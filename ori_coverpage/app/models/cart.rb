class Cart < LineItemCollection
  after_save :save_address
  after_save :save_spec
  after_save :destroy_authorization
  
  validates :payment_method, 
              :inclusion => { :in => ['Credit Card', 'Check/Money Order', 'Purchase Order'] },
              :if => Proc.new {|cart| !cart.payment_method.nil? }
  
  # Move line items from one cart to another.  
  # See AccountController#init_user_cart.
  def replaces(old_cart)
    transaction do
      product_ids = self.line_items.collect(&:product_id)
      old_cart.line_items.where(product_ids.blank? ? "true=true" : "product_format_id not in (select id from product_formats where product_id in (#{product_ids.join(",")}) )").all.each do |item|
        item.update_attributes(:saved_for_later => true, :line_item_collection_id => self.id)
      end
      self.update_attribute(:user, old_cart.user)
      Cart.destroy(old_cart.id)
    end
  end
  
  def update_shipping!(shipping_options)
    method = shipping_options.select do |m|
      m.service_code == self.shipping_method
    end.first || shipping_options.first
    
    # no shipping should be if there is no paper version...
    if method && !self.is_virtual?
      self.shipping_method = method.service_code
      self.shipping_amount = method.cost
    else
      self.shipping_method = nil
      self.shipping_amount = 0
    end
    self.save
  end
  
  def update_processing!(spec)
    if spec && CONFIG[:free_library_processing] != true
      # NB: AR quiz price is calculated separately of processing
      # TODO: data_disk_per_book_cost should actually be per unique product_format
      #   That is, one MARC record per product_format, thus charge per product_format
      per_book_price = (spec.include_disk ? 1 : 0) * CONFIG[:data_disk_per_book_cost]
      processing_amount = self.processing_count * per_book_price
      physical_per_book_price = (spec.include_readinglabels ? 1 : 0) * CONFIG[:reading_label_cost] + (spec.include_kits ? 1 : 0) * CONFIG[:catalog_card_cost] + (spec.include_labels ? 1 : 0) * CONFIG[:barcode_label_cost]
      physical_processing_amount = self.physical_processing_count * physical_per_book_price
      # virtual_per_book_price = 0
      # virtual_processing_amount = self.virtual_processing_count * virtual_per_book_price
      virtual_processing_amount = 0
      self.processing_amount = processing_amount + physical_processing_amount + virtual_processing_amount + (spec.include_disk ? 1 : 0) * CONFIG[:data_disk_cost]
    else
      self.processing_amount = 0
    end
    self.save
  end
  
  # calculates the total amount of paper copies (physical shipment)
  # to be used for shipping calculations (pdf's are not used as base of shipment price - digital downloads are free)
  def shipping_base_amount
    # sum total_amount of all line_items that:
    # a) are not virtual (see formats table, is_virtual)
    # b) are not saved for later (see line items table, saved_for_later)
    self.line_items.includes(:product_format => :format).where("formats.is_virtual != 1 AND (line_items.saved_for_later != 1 OR line_items.saved_for_later IS NULL)").map(&:total_amount).sum
  end
  
  def complete_sale(ship_address, bill_address, spec = nil)
    if self.user_id.nil?                        # a little overkill perhaps, but must check if user_id is filled
      self.errors.add( :user_id, :blank )         # if not, set an error
      raise ActiveRecord::RecordInvalid, self     # and raise exception (better than having a sale without user_id)
    end
    omit_fields = %w(addressable_id addressable_type type is_primary specable_id specable_type)
    @new_ship_address = ship_address.clone.attributes.delete_if {|k, v| omit_fields.include?(k)}
    @new_bill_address = bill_address.clone.attributes.delete_if {|k, v| omit_fields.include?(k)}
    @new_spec = spec.clone.attributes.delete_if {|k, v| omit_fields.include?(k)} unless spec.nil?
    
    self.discount_amount = self.calculate_discount
    self[:type] = 'Sale'
    self.completed_at = Time.now
    self.set_token
    self.add_products_to_user
    self.status = "Submitted"
    self.save!
  end
  
  def apply_taxes(address, spec = nil)
    # Override tax rate for institutions in certain zones
    tax_rate = if self.user && address.postal_code.zone
      if Customer::INSTITUTIONS.include?(self.user.category) && Zone::INSTITUTION_TAX_EXEMPT_CODES.include?(address.postal_code.zone.code)
        0
      end
    end
    tax_rate ||= address.postal_code.tax_rate
    tax_amount = (self.taxable_total(spec) * tax_rate).round(2)
    self.update_attribute(:tax, tax_amount) unless self.tax == tax_amount
  end

  def authorize_payment(new_auth, bill_address, spec = nil)
    raise ArgumentError, "bill_address must be specified" if bill_address.nil?
    raise ArgumentError, "bill_address must be a valid address" if !bill_address.valid?
    raise ArgumentError, "user_id must not be null" if user_id.nil?
    self.update_alsquiz!(spec)
    self.update_amount!
    self.apply_taxes(bill_address, spec)
    new_auth.address = bill_address
    new_auth.cart = self
    new_auth.save
  end
  
  def is_virtual?
    self.line_items.includes({:product_format => :format}).where("formats.is_virtual = false").all.size == 0
  end

  protected
  
    def save_address
      if @new_ship_address
        self.create_ship_address(@new_ship_address)
        @new_ship_address = nil
      end
      if @new_bill_address
        self.create_bill_address(@new_bill_address)
        @new_bill_address = nil
      end
    end
    
    def save_spec
      if @new_spec
        self.create_spec(@new_spec)
        @new_spec = nil
      end
    end

    def destroy_authorization
      return if self[:type] == 'Sale' # TODO: this can never be the case, correct? - Re TODO - inserted debug statement below that allows studying logs and see if this can happen (it happens in test mode; see issue #460)
      logger.debug("cart debug: cart #{self.id} : type '#{self[:type]}' -- destroying authorization; is it what you want?")
      if self.card_authorization
        self.card_authorization.destroy
      end
    end
    
    def add_products_to_user
      return false unless self.user # there might not be a user for visitors packing cart before signing up! return if so...
      sale_products = self.line_items.collect {|l| l.product_id }
      user_products = self.user.product_ids
      if (new_products = sale_products - user_products).any?
        self.user.products << Product.find(new_products)
      end
    end

end

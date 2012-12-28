class LineItemCollection < ActiveRecord::Base
  include TokenGenerator
  
  has_many :all_items, :dependent => :delete_all, 
    :class_name => "LineItem", :foreign_key => "line_item_collection_id"
  has_many :line_items, :dependent => :delete_all, 
    :conditions => 'saved_for_later is null'
  has_many :saved_items, :dependent => :delete_all, :class_name => "LineItem", 
    :foreign_key => "line_item_collection_id", :conditions => 'saved_for_later is not null'
  belongs_to :user
  has_one :spec, :as => :specable
  has_one :ship_address, :as => :addressable
  has_one :bill_address, :as => :addressable
  has_one :card_authorization, :dependent => :destroy
  belongs_to :discount
  accepts_nested_attributes_for :line_items
  attr_accessible :name, :user_id, :user, :comments, :payment_method, :line_items_attributes, :customer_id
  
  before_create :set_token
  before_save :set_amount, :destroy_line_items_with_zero_quantity
  
  def destroy_line_items_with_zero_quantity
    self.all_items.each {|li| li.destroy if li.quantity == 0}
  end
  
  def add_item(product_format, quantity = 1)
    quantity = quantity.to_i
    return false if product_format.nil? || quantity.blank? || quantity <= 0 
    self.save! if self.new_record?
    if item = self.line_items.find_by_product_format_id(product_format.id)
      item.update_attribute(:quantity, item.quantity + quantity.to_i)
    else
      item = self.line_items.create(:quantity => quantity, :unit_amount => product_format.price, :product_format_id => product_format.id)
    end
    item
  end
  
  def add_item_if_active(product_format, quantity = 1)
    product_format.active? ? add_item(product_format, quantity) : false
  end
  
  # this method finds redundant line_items (same product_id, format_id) within the collection,
  # sums them in the first line_item (matching the duplicate product_id, format_id)
  # and deletes the duplicates
  def merge_line_items
    processed_items = []
    self.line_items.each do |item|
      if processed_items.include?(item.product_format_id)
        item.destroy
      else
        duplicates = self.line_items.where("product_format_id = ?", item.product_format_id).all
        if duplicates.size > 1
          qty = duplicates.sum(&:quantity)
          amt = duplicates.sum(&:total_amount)
          item.update_attributes({:quantity => qty, :total_amount => amt})
        end
      end
      processed_items << item.product_format_id
    end
  end
  
  def update_item(id, quantity, product_format_id = nil)
    if item = LineItem.find(id)
      if quantity.to_i == 0
        item.destroy
      else
        values = {:quantity => quantity}
        unless product_format_id.blank?
          values.merge!({:product_format_id => product_format_id, :unit_amount => ProductFormat.find(product_format_id).price})
        end
        item.update_attributes(values)
      end
      self.update_amount!
      item
    end
  end
  
  def total_amount
    (self.amount.nil? ? 0 : self.amount) +
      (self.alsquiz_amount.nil? ? 0 : self.alsquiz_amount) +
      (self.tax.nil? ? 0 : self.tax) + 
      (self.shipping_amount.nil? ? 0 : self.shipping_amount) +
      (self.processing_amount.nil? ? 0 : self.processing_amount) - 
      self.calculate_discount
  end
  
  # counts number of unique items
  def item_count
    self.line_items.any? ? self.line_items.count : 0
  end
  
  # counts number of units of all items (units = item * quantity)
  def unit_count
    # Assuming items are available if in cart -- check is made at that time
    # Assuming that a format has only 1 processing unit
    # Assuming that an assembly has same amount of titles no matter what format
    items = self.line_items.includes(:product_format => [:format, :product])
    items.inject(0) {|sum, item| sum + item.quantity * item.product_format.format.units}
  end
  
  # counts *all* units in the collection, including digitals
  def title_count
    # Assuming items are available if in cart -- check is made at that time
    # Assuming that a format has only 1 processing unit
    # Assuming that an assembly has same amount of titles no matter what format
    items = self.line_items.includes(:product_format => [:format, :product])
    items.inject(0) {|sum, item| sum + item.product_format.title_count * item.quantity * item.product_format.format.units}
  end
  
  # counts units with format 'is_processed' = true in the collection
  def processing_count
    # Assuming items are available if in cart -- check is made at that time
    # Assuming that a format has only 1 processing unit
    # Note: 'units' column in formats table refers to physical units not processing units
    items = self.line_items.includes(:product_format => [:format, :product]).where("formats.is_processed = ?", true)
    items.inject(0) {|sum, item| sum + item.product_format.title_count * item.quantity}
  end

  # counts units with format 'is_processed' = true and format 'is_virtual' = false in the collection
  def physical_processing_count
    # Assuming items are available if in cart -- check is made at that time
    # Assuming that a format has only 1 processing unit
    # Note: 'units' column in formats table refers to physical units not processing units
    items = self.line_items.includes(:product_format => [:format, :product]).where("formats.is_processed = ?", true)
    items.inject(0) {|sum, item| sum + item.product_format.physical_title_count * item.quantity}
  end

  # counts units with format 'is_processed' = true and format 'is_virtual' = true in the collection
  def virtual_processing_count
    # Assuming items are available if in cart -- check is made at that time
    # Assuming that a format has only 1 processing unit
    # Note: 'units' column in formats table refers to physical units not processing units
    items = self.line_items.includes(:product_format => [:format, :product]).where("formats.is_processed = ?", true)
    items.inject(0) {|sum, item| sum + item.product_format.virtual_title_count * item.quantity}
  end

  # counts the number of accelerated reader quizzes for the collection
  # it uses a single SQL statement to get a distinct list of products for the collection
  # (a product only listed once, even if the collection contains multiple copies of
  # the product by having one or more assembly in the collection that contain the product)
  # also, the products must have something in the alsquiznr field.
  #
  # !!! use this method if want to have a collection's alsquiznr as adding assembly' and sub-assembly'
  # alsquiz_counts together will multiply products' counters included in both assemblies !!! 
  def alsquiz_count
    # Assuming items are available if in cart -- check is made at that time
    ids = self.line_items.map(&:product_id)
    Title.includes(:assembly_assignments).where(["alsquiznr IS NOT NULL AND alsquiznr != '' AND (products.id IN (?) OR assembly_assignments.assembly_id IN (?))", ids, ids]).all.count
  end
  
  # calculates the taxable amount -> total amount + (if library processing was requested) alsquiz costs
  def taxable_total(spec = nil)
    items_total = self.line_items.includes(:product_format).all.collect do |i|
      i.saved_for_later != 1 || i.saved_for_later.nil? ? (i.product.is_taxable? ? i.total_amount : 0) : 0
    end.sum
    mspec = spec.nil? ? self.spec : spec
    (items_total + (mspec.nil? ? 0 : self.processing_amount + (mspec.include_tests ? (self.alsquiz_amount.nil? ? 0 : self.alsquiz_amount) : 0)) - (self.calculate_discount))
  end
  
  # calculates and saves the number of accelerated reader quizzes for the cart
  # if there are more than the minimum required AR-titles then calculate AR price otherwise no AR Quizzes
  # see CONFIG[:alsquiz_min_limit] and CONFIG[:alsquiz_unit_price] in config/environment.rb
  def update_alsquiz!(spec = nil)
    unless spec.nil? || spec.include_tests != true
      newalsquiz_amount =  self.alsquiz_count >= CONFIG[:alsquiz_min_limit] ? self.alsquiz_count * CONFIG[:alsquiz_unit_price] : 0
    else
      newalsquiz_amount = 0
    end
    self.update_attribute(:alsquiz_amount, newalsquiz_amount)
  end
  
  def calculate_amount
    self.line_items.collect(&:total_amount).sum
    # TODO This code causes bug #394. Tests pass when commented. What was the purpose? Troublesome
    # if self.new_record?
    #   self.line_items.collect(&:total_amount).sum
    # else
    #   self.line_items.reload.collect(&:total_amount).sum
    # end
  end
  
  def set_amount
    # with partial update functionality, this will not force update if the value does not change
    self.amount = self.calculate_amount unless self.is_a?(Sale)
  end
  
  def update_amount!
    new_total = self.calculate_amount
    logger.debug { "@@@ BEFORE total=#{self.amount}" }
    self.update_attribute(:amount, new_total) unless new_total == self.amount
    logger.debug { "@@@ AFTER total=#{self.amount}" }
    true # TODO: is this needed?
  end
  
  def discounted?
    self.calculate_discount > 0
  end
  
  def discount_amount
    self[:discount_amount] > 0 ? self[:discount_amount] : self.calculate_discount
  end
  
  def calculate_discount
    return self[:discount_amount] if self.is_a?(Sale)
    self.bundle_discount + (
      self.discount ? self.discount.calculate(self.amount - self.bundle_discount) : 0
    )
  end
  
  def bundle_discount
    self.bundles.collect {|bundle| bundle.calculated_amount }.sum
  end
  
  def products
    self.line_items.inject({}) do |products, item|
      products[item.product_id] = { 
        :price => item.unit_amount, :quantity => item.quantity 
      }
      products
    end
  end
  
  def bundles
    ([]).tap do |bundles|
      product_list = self.products.dup
      while product_list.any? do
        # Find the biggest discount based on the products not yet discounted
        break unless bundle = Bundle.for_products(product_list.keys, self.discount_code).sort_by do |bundle|
          bundle.calculate(product_list.values_at(*bundle.product_ids).collect {|p| p[:price]}.sum)
        end.last
      
        # Remove the products used for the just-found bundle
        bundle.product_ids.each do |product|
          if product_list[product][:quantity] == 1
            product_list.delete(product)
          else
            product_list[product][:quantity] -= 1
          end
        end
        bundles << bundle
      end
    end
  end
  
  def copy_from_cart(cart)
    cart.line_items.each do |item|
      self.line_items << item.clone
    end
    self.update_amount!
  end
  
  def copy_to_cart(cart, replace = true)
    cart.save! if cart.new_record?
    cart.line_items.clear if replace
    ok = true
    self.line_items.each do |item|
      ok = false unless cart.add_item_if_active(item.product_format, item.quantity)
    end
    cart.update_amount!
    return ok
  end
  
  # Remove product formats that are inactive
  def save_for_later_inactive_line_items!
    self.line_items.each do |item|
      item.update_attribute(:saved_for_later, true) unless item.product_format.active?
      # item.destroy unless item.product_format.active?
    end
    self.update_amount!
  end
  
end

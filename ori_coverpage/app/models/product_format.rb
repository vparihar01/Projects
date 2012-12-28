class ProductFormat < ActiveRecord::Base
  belongs_to :product
  belongs_to :format
  has_many :line_items
  has_many :errata
  has_many :price_changes
  
  versioned
  
  validates :status, :inclusion => { :in => APP_STATUSES.keys }
  validates :product_id, :presence => true
  validates :format_id, :presence => true
  validates :isbn, :presence => true, :uniqueness => true
  validate :must_refer_to_valid_records
  validates :isbn, :isbn_format => { :with => :isbn13 }, :if => :format_requires_valid_isbn?
  
  before_save :calculate_list_price, :calculate_ebook_price
  after_save :calculate_assembly_price
  
  # fields in product_formats table that begin with 'price'
  PRICE_FIELDS = column_names.reject{|col| !/^price/.match(col)}.freeze
  ACTIVE_STATUS_CODE = 'ACT'
  REPLACED_STATUS_CODE = 'RPL'
  # translates our status codes (as defined in config/app_statuses.yml)
  # to ONIX ProductAvailability code (PR.24.22, List 65)
  STATUS_TO_AVAILABILITY = {
    'PC' => 1,
    'NYP' => 10,
    'PP' => 10,
    'ACT' => 20,
    'NLO' => 43,
    'OS' => 31,
    'OSI' => 31,
    'OP' => 40,
    'INA' => 40,
    'UN' => 43,
    'REM' => 47,
    'WD' => 46,
    'RE' => 49,
    'RPL' => 41,
  }
  # EXCHANGE_RATES: 1 USD to foreign currency
  # - Keys should correspond to ONIX list 96
  EXCHANGE_RATES = {
    'GBP' => 0.6311,
    'USD' => 1,
  }

  scope :active, includes(:product).where("product_formats.status = '#{ACTIVE_STATUS_CODE}' and products.available_on <= NOW()")
  scope :available_between, lambda { |start_date, end_date|
    filter = includes(:product)
    filter = filter.where('products.available_on <= ?', end_date) unless end_date.blank?
    filter = filter.where('products.available_on >= ?', start_date) unless start_date.blank?
    filter
  }
  scope :title_formats, lambda { |assembly_format|
    if assembly_format.product.respond_to?(:titles)
      ids = assembly_format.product.titles.map(&:id)
    else
      ids = nil
    end
    where(:product_id => ids).where(:format_id => assembly_format.format_id)
  }

  def must_refer_to_valid_records
    errors.add(:base, "Invalid Product ID provided") if self.product.nil? && !product_id.nil?
    errors.add(:base, "Invalid Format ID provided") if self.format.nil? && !format_id.nil?
  end
  
  # ONIX ProductAvailability code (PR.24.22, List 65) inferred by product format status
  def availability
    STATUS_TO_AVAILABILITY[self.status]
  end

  def active?
    self.status == ACTIVE_STATUS_CODE && self.product && self.product.available?
  end

  def self.find_using_options(options = {})
    options.symbolize_keys!
    FEEDBACK.debug("ProductFormat.find_using_options")
    FEEDBACK.debug("options = #{options.inspect}")
    case options[:product_select]
    when "by_date"
      available_between(options[:start_date], options[:end_date])
    when "by_season"
      start_date, end_date = Coverpage::Utils.season_to_dates(options[:season])
      available_between(start_date, end_date)
    when "by_isbn"
      if options[:isbns].is_a?(String)
        isbns = options[:isbns].split(',').map{|i| i.strip}
      elsif options[:isbns].is_a?(Array)
        isbns = options[:isbns]
      else
        isbns = nil
      end
      includes(:product).where(:isbn => isbns)
    else
      Rails.logger.debug("# DEBUG: unrecognized 'product_select' value -- use ProductFormat class")
      self
    end
  end

  # By creating or destroying an assignment, we are in effect changing 
  # the parts within an assembly. Thus, we need to recalculate
  # the price of the assembly -- every price (eg, list, member) and
  # every format (eg, hardcover, pdf)
  # after saving a product format, should recalculate prices for associated assembly
  def calculate_assembly_price
    logger.debug("Running product_format.calculate_assembly_price method")
    logger.debug("  self = #{self.product.name} -- #{self.to_s} (#{self.id})")
    if self.price_changed?
      if CONFIG[:calculate_assembly_price] == true
        # assembly price is sum of constituent prices
        if self.product.respond_to?(:assemblies)
          self.product.assemblies.each do |assembly|
            logger.debug("  assembly = #{assembly.name} (#{assembly.id})")
            logger.debug("product format id = #{self.format_id}")
            # skip calculation if assembly does not have said format
            if assembly.product_formats.any? && assembly_format = assembly.product_formats.find_by_format_id(self.format_id)
              logger.debug("Continue: Assembly has similar product format (#{self.format_id})")
              PRICE_FIELDS.each do |price|
                # total is sum of respective product prices in assembly
                total = assembly_format.product.titles.map do |title|
                  (pf = title.product_formats.find_by_format_id(self.format_id)) ? pf.send(price) : 0
                end.sum
                logger.debug("Old total = #{self.price}")
                logger.debug("New total = #{total}")
                assembly_format.send("#{price}=", total)
              end
              assembly_format.save
            else
              logger.debug("Skip: Assembly does not have similar product format (#{self.format_id})")
            end
          end
        end
      end
    else
      logger.debug("Skip: Price did not change")
    end
  end
  
  def to_s
    self.format.name
  end

  # *** calculate_assembly_price takes precedence over calculate_list_price
  # if calculate_list_price == true && calculate_assembly_price == true -> assembly list is sum of parts list
  # if calculate_list_price == true && calculate_assembly_price == false -> assembly list is calculated from member ***
  # if calculate_list_price == false && calculate_assembly_price == true -> assembly list is sum of parts list
  # if calculate_list_price == false && calculate_assembly_price == false -> assembly list is user-defined
  def calculate_list_price
    logger.debug("Running product_format.calculate_list_price method")
    logger.debug("  self = #{self.product.name} -- #{self.to_s} (#{self.id})")
    logger.debug("  price_change = #{self.price_change.inspect}")
    if self.product.is_a?(Title) && CONFIG[:calculate_list_price] != true
      logger.debug("Skip: Config calculate_list_price set to FALSE")
    elsif !self.product.is_a?(Title) && CONFIG[:calculate_list_price] == true && CONFIG[:calculate_assembly_price] == true
      logger.debug("Skip: Assembly list price calculated as sum of parts")
    # elsif !self.product.is_a?(Title) && CONFIG[:calculate_list_price] == true && CONFIG[:calculate_assembly_price] != true # ***
      # logger.debug("Skip: Assembly list price calculated as sum of parts")
    elsif !self.product.is_a?(Title) && CONFIG[:calculate_list_price] != true && CONFIG[:calculate_assembly_price] == true
      logger.debug("Skip: Assembly list price calculated as sum of parts")
    elsif !self.product.is_a?(Title) && CONFIG[:calculate_list_price] != true && CONFIG[:calculate_assembly_price] != true
      logger.debug("Skip: Assembly list price is user-defined")
    elsif !self.price_changed?
      logger.debug("Skip: Price has not changed")
    else
      self.price_list = (self.price / CONFIG[:member_price_decimal]).round(2)
      logger.debug("New price_list = #{self.price_list}")
    end
  end
  
  def calculate_ebook_price(force = false)
    # TODO: introduced force to allow rake task to calculate ebook prices
    # it isn't fully thought out much but it seems to work
    logger.debug("Running product_format.calculate_ebook_price method")
    logger.debug("  self = #{self.product.name} -- #{self.to_s} (#{self.id})")
    logger.debug("  price_change = #{self.price_change.inspect}")
    if CONFIG[:calculate_ebook_price] != true && !force
      logger.debug("Skip: Config calculate_ebook_price set to FALSE")
    elsif !self.product.is_a?(Title) && !force
      logger.debug("Skip: Self is not a Title")
    elsif self.format_id != Format::DEFAULT_ID && !force
      logger.debug("Skip: Should only calculate if default format has changed")
    elsif !self.product.pdf_format && !force
      logger.debug("Skip: Related product doesn't have pdf format")
    elsif !self.price_changed? && !force
      logger.debug("Skip: Price has not changed")
    else
      # ebook price is a function of default price
      self.price = self.product.default_format.price if force
      if !self.price.blank?
        if CONFIG[:ebook_price_decimal] == 1
          # Set ebook price to default price
          ebook_price = self.price
        else
          # Set ebook price to fraction of default price plus $0.95
          ebook_price = ( self.price == 0 ? 0 : (self.price * CONFIG[:ebook_price_decimal]).round + 0.95 )
        end
      else
        # use ebook_fallback_price if no default format or its price is nil
        ebook_price = CONFIG[:ebook_fallback_price]
      end
      logger.debug("New price for ebook = #{ebook_price}")
      self.product.pdf_format.update_attribute(:price, ebook_price)
    end
  end

  def change_price_by(amount, options = {})
    change_price_to(self.price + amount, options)
  end

  def change_price_to(amount, options = {})
    implement_on = options[:implement_on] || Product.upcoming_on
    # TODO: This is hard-coded. Need relation between PRICE_FIELDS and price calculations
    FEEDBACK.debug("Running product_format.change_price_to method")
    FEEDBACK.debug("  self = #{self.product.name} -- #{self.to_s} (#{self.id})")
    prices = PRICE_FIELDS.map{|x| self.send(x)}.join(" / ")
    FEEDBACK.debug("    Current: #{prices}")
    new_price = amount
    new_price_list = (new_price / CONFIG[:member_price_decimal]).round(2)
    data = {:product_format_id => self.id, :price => new_price, :price_list => new_price_list, :implement_on => implement_on}
    pc = PriceChange.create(data)
    prices = PRICE_FIELDS.map{|x| pc.send(x)}.join(" / ")
    FEEDBACK.debug("    Price Change on #{pc.implement_on}: #{prices}")
    if options[:update_assemblies] == true
      if self.product.respond_to?(:assemblies) && self.product.assemblies.any?
        apfs = self.product.assemblies.map {|a| a.product_formats.find_by_format_id(self.format_id)}.compact
        apfs.each {|apf| apf.change_price_to_sum_of_subproducts(:implement_on => implement_on)}
      end
    end
    pc
  end

  def change_price_to_sum_of_subproducts(options = {})
    implement_on = options[:implement_on] || Product.upcoming_on
    FEEDBACK.debug("Running product_format.change_price_to_sum_of_subproducts method")
    FEEDBACK.debug("  self = #{self.product.name} -- #{self.to_s} (#{self.id})")
    return nil unless self.product.is_a?(Assembly)
    prices = PRICE_FIELDS.map{|x| self.send(x)}.join(" / ")
    FEEDBACK.debug("    Current: #{prices}")
    data = {:product_format_id => self.id, :implement_on => implement_on}
    change = false
    PRICE_FIELDS.each do |price|
      # total is sum of respective product prices in assembly
      total = self.product.titles.map do |title|
        if pf = title.product_formats.find_by_format_id(self.format_id)
          if pc = pf.price_changes.where('implement_on <= ?', implement_on).order(:implement_on).first
            pc.send(price)
          else
            pf.send(price)
          end
        else
          0
        end
      end.sum
      change = true unless total == self.send(price)
      data[price.to_sym] = total
    end
    unless change
      FEEDBACK.debug("    No price change")
      return nil
    end
    pc = PriceChange.create(data)
    prices = PRICE_FIELDS.map{|x| pc.send(x)}.join(" / ")
    FEEDBACK.debug("    Price Change on #{pc.implement_on}: #{prices}")
    pc
  end

  def price_agency
    self.price_list.floor + 0.99
  end

  def price_foreign(currency)
    if rate = EXCHANGE_RATES[currency]
      (self.price_list * rate).round(2)
    end
  end

  def isbn_obj
    ISBN.new(self.isbn)
  end
  
  def is_isbn_valid?
    isbn_obj.is_valid
  end
  
  def isbn13
    isbn_obj.isbn13
  end
  
  def isbn10
    isbn_obj.isbn10
  end
  
  def isbn13str
    isbn_obj.isbn13str
  end
  
  def isbn10str
    isbn_obj.isbn10str
  end

  def name
    "#{self.product.name} - #{self.format.name}"
  end
  
  def width
    dimensions_array[0]
  end
  
  def height
    dimensions_array[1]
  end

  def title_count
    self.product.respond_to?(:titles) ? self.product.titles.count : 1
  end
  
  def physical_title_count
    self.format.is_virtual ? 0 : title_count
  end
  
  def virtual_title_count
    self.format.is_virtual ? title_count : 0
  end
  
  def sum_of_title_prices(price_field, use_price_change = false)
    (raise ArgumentError, "is not included in the list #{PRICE_FIELDS.inspect}") unless PRICE_FIELDS.include?(price_field.to_s)
    return nil unless self.product.respond_to?(:titles)
    # total is sum of respective product prices in assembly
    total = self.product.titles.map do |title|
      if pf = title.product_formats.find_by_format_id(self.format_id)
        if use_price_change && (price_change = pf.price_changes.where('state != ?', 'implemented').order(:implement_on).last)
          # Using the last price change that has yet to be implemented
          price_change.send(price_field)
        else
          pf.send(price_field)
        end
      else
        0
      end
    end.sum
  end

  def is_price_equal_sum?(price_field, use_price_change = false)
    (raise ArgumentError, "is not included in the list #{PRICE_FIELDS.inspect}") unless PRICE_FIELDS.include?(price_field.to_s)
    return true unless self.product.respond_to?(:titles)
    if use_price_change && (price_change = self.price_changes.where('state != ?', 'implemented').order(:implement_on).last)
      sum_of_title_prices(price_field, use_price_change) == price_change.send(price_field)
    else
      sum_of_title_prices(price_field, use_price_change) == self.send(price_field)
    end
  end

  PRICE_FIELDS.each do |price_field|
    define_method("#{price_field}_on") do |date|
      value_on(price_field, date)
    end
    define_method("suggested_#{price_field}_on") do |date|
      suggested_value_on(price_field, date)
    end
  end

  def feedback
    fields = [self.isbn, self.product.try(:name), self.to_s, self.product.collection.try(:name_extended), self.product.try(:publisher), self.product.try(:available_on), self.status, self.price, self.price_on(Product.upcoming_on)]
    FEEDBACK.verbose(fields.join(', '))
  end

  private

  def value_on(price_field, date)
    (raise ArgumentError, "is not included in the list #{PRICE_FIELDS.inspect}") unless PRICE_FIELDS.include?(price_field.to_s)
    base = nil
    if date && date > Date.today
      base = PriceChange.where('state != ?', 'implemented').where('implement_on <= ?', date).where(:product_format_id => self.id).order(:implement_on).last
    end
    (base || self).send(price_field)
  end

  def suggested_value_on(price_field, date)
    (raise ArgumentError, "is not included in the list #{PRICE_FIELDS.inspect}") unless PRICE_FIELDS.include?(price_field.to_s)
    return nil unless self.product.is_a?(Assembly)
    # Assembly list price calculated as sum of title prices
    self.class.title_formats(self).map do |tf|
      tf.price_list_on(date)
    end.sum
  end

  def dimensions_array
    dimensions.blank? ? [nil,nil] : dimensions.split(" x ").map {|d| d.to_f}
  end

  def format_requires_valid_isbn?
    self.format && self.format.requires_valid_isbn == true
  end

end

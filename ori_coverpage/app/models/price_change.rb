class PriceChange < ActiveRecord::Base
  belongs_to :product_format, :include => :product

  # Ensure user can't create new price_change when one already exists
  class UniqueValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors[attribute] << "already exists" if PriceChange.where("state = ?", 'new').where("product_format_id = ?", record.product_format_id).where("id != ?", record.id.to_s).first
    end
  end

  validates :product_format_id, :presence => true, :unique => true
  validates_numericality_of :price_list, :greater_than_or_equal_to => 0
  validates_numericality_of :price, :greater_than_or_equal_to => 0
  validate :valid_date?

  def valid_date?
    unless Chronic.parse(implement_on)
      errors.add(:implement_on, "is not a valid date")
    end
  end

  scope :undistributed, where('price_changes.implement_on <= ? and price_changes.state = ?', Date.today + CONFIG[:price_change_notice].days, 'new')
  scope :unimplemented, where('price_changes.implement_on <= now() and price_changes.state = ?', 'distributed')

  include ActiveRecord::Transitions

  state_machine do
    state :new
    state :distributed
    state :implemented

    event :distribute do
      transitions :to => :distributed, :from => :new, :on_transition => :distribute
    end

    event :implement do
      transitions :to => :implemented, :from => :distributed, :on_transition => :implement
    end
  end

  VALID_STATES = self.state_machines[:default].states.map(&:name).freeze

  # class method to distribute all new price changes
  # note: batches individual price changes into one 'distribution'
  def self.distribute(options = {})
    FEEDBACK.debug "PriceChange.distribute"
    price_changes = self.includes(:product_format => :product).undistributed
    if price_changes.any?
      FEEDBACK.debug "New price changes found"
      products = price_changes.map{|x| x.product_format.try(:product)}.compact
      # Perform notifications; if all successful, than update price_change requests
      results = DataRecipient.distribute_all(options.merge(:data_template => 'price_change', :product_select => 'by_id', :ids => products.map(&:id), :verbose => false))
      # result is a hash with recipient name as key
      # It is possible that distribution works for some but not others
      # Regardless, I'm marking the price change as sent if anyone received
      if results.values.include?(true)
        price_changes.each do |price_change|
          price_change.distribute!
        end
      end
    else
      FEEDBACK.debug "Skipping: No new price changes found"
      results = {}
    end
    FEEDBACK.debug "results = #{results.inspect}"
    results
  end

  def self.find_new_price_change_by_product_format_id(id)
    self.where("state = ?", 'new').where("product_format_id = ?", id).last
  end

  def price_agency
    self.price_list.floor + 0.99
  end

  def price_foreign(currency)
    if rate = ProductFormat::EXCHANGE_RATES[currency]
      (self.price_list * rate).round(2)
    end
  end

  def suggested_price_list
    (raise StandardError, "Price change (#{self.id}) is not associated with a product_format") unless product_format = self.product_format
    (raise StandardError, "Price change (#{self.id}) is not associated with a product") unless product = product_format.product
    if product.is_a?(Assembly)
      # Assembly list price calculated as sum of title prices
      ProductFormat.title_formats(product_format).map do |tf|
        tf.price_list_on(self.implement_on)
      end.sum
    else
      (self.price / CONFIG[:member_price_decimal]).round(2)
    end
  end

  def has_price_changes_for_all_formats?
    (raise StandardError, "Price change (#{self.id}) is not associated with a product_format") unless product_format = self.product_format
    (raise StandardError, "Price change (#{self.id}) is not associated with a product") unless product = product_format.product
    other_formats = ProductFormat.where(:product_id => product.id).where('id != ?', self.product_format_id).where('isbn is not NULL').where('isbn != ""')
    if other_formats.any?
      missing_price_changes = other_formats.detect {|pf| !pf.price_changes.where(:implement_on => self.implement_on).any?}
      missing_price_changes.nil?
    else
      true
    end
  end

  def has_matching_price_changes_for_all_formats?
    (raise StandardError, "Price change (#{self.id}) is not associated with a product_format") unless product_format = self.product_format
    (raise StandardError, "Price change (#{self.id}) is not associated with a product") unless product = product_format.product
    other_formats = ProductFormat.where(:product_id => product.id).where('id != ?', self.product_format_id)
    if other_formats.any?
      missing_price_changes = other_formats.detect {|pf| !pf.price_changes.where(:implement_on => self.implement_on).where(:price => self.price).where(:price_list => self.price_list).any?}
      missing_price_changes.nil?
    else
      true
    end
  end

  def feedback
    fields = [self.product_format.isbn, self.product_format.product.proprietary_id, self.product_format.product.name, self.product_format.to_s, self.product_format.product.collection.try(:name_extended), self.product_format.product.publisher, self.product_format.product.available_on, self.product_format.status, self.product_format.price, self.product_format.price_on(Product.upcoming_on)]
    FEEDBACK.verbose(fields.join(', '))
  end

  private

    def distribute(started_at = Time.now)
      Rails.logger.debug "distribute (instance)"
      # instance method -- we don't want a per record distribution
      # therefore this functionality is on the class level (see PriceChange.distribute)
    end

    def implement(finished_at = Time.now)
      Rails.logger.debug "implement (instance)"
      if Time.now >= self.implement_on
        self.product_format.update_attributes(:price => self.price, :price_list => self.price_list)
        Rails.logger.debug "Implemented price change"
      else
        # should we throw an error? it's too early to carry out the price change
        Rails.logger.debug "Skipped price change because effective date not reached"
        false
      end
    end

end

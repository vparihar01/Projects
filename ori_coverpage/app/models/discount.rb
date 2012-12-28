class Discount < ActiveRecord::Base
  has_many :line_item_collections

  before_save :upcase

  attr_accessor :calculated_amount

  def available?
    return false if self.start_on && self.start_on > Time.now.to_date
    return false if self.end_on && self.end_on < Time.now.to_date
    true
  end

  def calculate(subtotal)
    return 0 unless subtotal.to_i > 0
    return 0 unless self.available?
    self.calculated_amount = if self.percent
      (self.amount * subtotal).round(2)
    else
      self.amount > subtotal ? subtotal : self.amount
    end
  end

  def start_on=(start_date)
    if start_date.is_a?(String)
      self[:start_on] = start_date.blank? ? nil : Chronic.parse(start_date)
    else
      self[:start_on] = start_date
    end
  end

  def end_on=(end_date)
    if end_date.is_a?(String)
      self[:end_on] = end_date.blank? ? nil : Chronic.parse(end_date)
    else
      self[:end_on] = end_date
    end
  end

  def self.to_dropdown
    order('name ASC').collect {|d| [d.name, d.id]}
  end

  protected

  def upcase
    self.code = self.code.upcase unless self.code.blank?
  end

end

class Erratum < ActiveRecord::Base
  belongs_to :user
  belongs_to :product_format, :include => :product
  has_many :status_changes, :as => :status_changeable, :dependent => :delete_all, :order => 'created_at asc'

  VALID_STATUSES = %w(Submitted Accepted Refused Fixed Published).freeze
  VALID_TYPES = %w(Typo TechnicalError Suggestion).freeze

  validates :user_id, :presence => true,
            :if => Proc.new { CONFIG[:errata_login_required] == true }

  validates :status, :inclusion => { :in => VALID_STATUSES }, :allow_nil => false
  validates :erratum_type, :presence => true, :inclusion => { :in => VALID_TYPES }, :allow_nil => false

  validates :page_number, :presence => true
  validates :description, :presence => true
  validates :product_format_id, :presence => true

  # TODO: validations

  before_save :create_status_change_if_changed

  def create_status_change_if_changed
    self.status_changes.create(:status => self.status) if self.status_changed?
  end

  def product
    self.product_format.product unless self.product_format.nil?
  end

end

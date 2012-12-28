class Contract < ActiveRecord::Base
  belongs_to :sales_zone
  belongs_to :sales_team
  has_many :invoices, :order => 'posted_on desc'
  has_many :credits, :order => 'posted_on desc'
  
  validates :start_on, :presence => true
  validates :rate, :presence => true
  
  before_save :check_other_contracts
  
  CATEGORIES = %w(All Library School).freeze
  
  protected
  
    def before_validations
      [:start_on, :end_on].each do |f|
        self[f] = Chronic.parse(self[f]) if self[f]
      end
    end
    
    def check_other_contracts
      # If the category is all, there can be no other contracts for the zone.
      # Otherwise, check that there are no contracts for All or for the same
      # category
      conditions = [ "sales_zone_id = :sales_zone_id" ]
      
      if self.category == 'All'
        message = "Cannot create a contract for this sales zone with the category of 'All' since other contracts already exist for this sales zone"
        categories = []
      else
        message = "Another contract for this zone covers the same category (or has the category of 'All')"
        categories = ['All', self.category].uniq
        conditions << "category in (:categories)"
      end
      conditions << "id <> :id" unless self.new_record?
      
      if self.class.count(:conditions => [ conditions.join(' and '), { :categories => categories, :id => self.id, :sales_zone_id => self.sales_zone_id } ]) > 0
        errors.add(:base, message)
        return false
      end
      
      true
    end
end

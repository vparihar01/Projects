class SalesTeam < ActiveRecord::Base
  has_many :contracts
  has_many :sales_zones, :through => :contracts
  has_many :sales_reps
  belongs_to :head_sales_rep, :class_name => "SalesRep", :foreign_key => "managed_by"
  has_many :invoices, :order => 'posted_on desc'
  has_many :credits, :order => 'posted_on desc'
  has_many :posted_transactions, :order => 'posted_on desc'
  has_many :customers, :through => :posted_transactions, :group => 'users.id'
  has_many :sales_targets
  has_many :quotes
  has_one :address, :as => :addressable, :dependent => :delete
  accepts_nested_attributes_for :address

  validates :name, :presence => true
  validates :email, :allow_blank => true, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}

  CATEGORIES  = %w(Small Medium Large).freeze

  def to_s
    name
  end

  def self.to_dropdown
    order('name ASC').collect {|t| [t.name, t.id]}
  end

  def ytd_sales
    last_year = (now = Time.now) - 1.year
    sales_query = <<-SQL
      select z.name as zone, c.category, sum(pt.transaction_amount ) as amount
      from posted_transactions pt left join users c on (pt.customer_id = c.id)
        left join addresses a on c.id = a.addressable_id and a.addressable_type = 'User'
        left join postal_codes pc on a.postal_code_id = pc.id
        left join zones z on pc.zone_id = z.id
      where pt.sales_team_id = #{self.id}
        and pt.posted_on between '%s' and '%s'
      group by zone, category
    SQL

    current_sales = self.connection.select_all(
      sales_query % [ now.at_beginning_of_year.to_s(:db), now.to_s(:db) ]
    ).group_by {|s| s['zone'] }
    previous_sales = self.connection.select_all(
      sales_query % [ last_year.at_beginning_of_year.to_s(:db), last_year.to_s(:db) ]
    ).group_by {|s| s['zone'] }

    [ current_sales, previous_sales ]
  end

  def sales_total(sales = nil)
    unless sales
      sales, old_sales = self.ytd_sales
    end
    sales.collect do |zone, types|
      types.sum {|t| t['amount'] }
    end.sum
  end

  def current_sales_target
    self.sales_targets.find_by_year(Time.now.year).amount rescue 0
  end

  def minimum_bonus
    self.current_sales_target * 0.1
  end

end

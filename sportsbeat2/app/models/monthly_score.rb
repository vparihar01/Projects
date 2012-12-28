class MonthlyScore < ActiveRecord::Base
  belongs_to :user

  validates :user_id, :presence => true
  validates :year, :presence => true
  validates :month, :presence => true, :inclusion => {:in => 1..12}
  validates :value, :presence => true
  validates_uniqueness_of :user_id, :scope => [:year, :month]

  def self.find_or_create_for(user, year = nil, month = nil)
    if month.nil? || year.nil?
      today = Date.today
      month = today.month
      year = today.year
    end

    ms = MonthlyScore.where(:user_id => user.id, :year => year, :month => month).first

    if ms.nil?
      ms = MonthlyScore.new
      ms.user = user
      ms.year = year
      ms.month = month
      ms.value = 0
      ms.save!
    end

    return ms
  end

  def self.previous(year, month)
    m = month - 1
    y = year

    if m < 1
      m = 12
      y = year - 1
    end

    return y, m
  end

  def self.rebuild_for user
    MonthlyScore.transaction do
      MonthlyScore.where(:user_id => user.id).update_all(:value => 0)

      last_month = 0
      last_year = 0
      monthly = nil

      UserScore.where(:user_id => user.id).find_each do |s|
        if s.pending
          next
        end

        if s.created_at.year != last_year || s.created_at.month != last_month
          monthly.save! unless monthly.nil?
          last_year = s.created_at.year
          last_month = s.created_at.month
          monthly = find_or_create_for(user, last_year, last_month)
        end

        monthly.value = monthly.value + s.value
      end

      monthly.save! unless monthly.nil?
    end
  end

  def self.total_for user
    MonthlyScore.where(:user_id => user.id).sum(:value)
  end
end

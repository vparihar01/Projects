class Contest < ActiveRecord::Base
  has_many :contest_users, :dependent => :destroy
  has_many :contest_votes, :dependent => :destroy
  has_many :users, :through => :contest_users

  validates :name, :presence => true
  validates :start, :presence => true
  validates :end, :presence => true

  def self.active
    today = Time.zone.now
    where('start <= ? AND end > ?', today, today).order('end ASC')
  end

  def self.eligible? user
    Contest.active.select {|c| c.eligible? user}
  end

  def self.inactive
    today = Time.zone.now
    where('end < ?', today).order('end DESC')
  end

  def self.participating? user
    Contest.joins(:contest_users).where(:contest_users => {:user_id => user.id})
  end

  def accepting_entries?
    today = Time.zone.now
    return (entry_end > today)
  end

  def currently_active?
    today = Time.zone.now
    return (start <= today && self.end > today)
  end

  def inactive
    today = Time.zone.now
    return self.end < today
  end

  def initialize
    raise "Abstract Contest cannot be initialized" if self.class == Contest
    super
  end

  def eligible? user
    cu = contest_users.where(:user_id => user.id).first
    
    if cu.nil?
      cu = ContestUser.new
      cu.contest = self
      cu.user = user
      cu.save!
    end

    return false
  end

end

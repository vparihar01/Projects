class Position < ActiveRecord::Base
  attr_accessible :sport_id, :name, :abbrev

  belongs_to :sport
  has_and_belongs_to_many :athlete_teams
  validates :sport, :presence => true
  validates :name, :presence => true

  def short_name
    abbrev.blank? ? name : abbrev
  end
end

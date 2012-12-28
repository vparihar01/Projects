class AthleteTeam < ActiveRecord::Base
  belongs_to :season, :inverse_of => :athlete_teams
  belongs_to :athlete, :inverse_of => :athlete_teams
  belongs_to :team, :inverse_of => :athlete_teams
  has_and_belongs_to_many :positions

  validates :athlete_id, :presence => true
  validates :team_id, :presence => true
  validates :season_id, :presence => true

  def activate!
    AthleteTeam.transaction do
      AthleteTeam.where(:athlete_id => athlete_id, :season_id => season_id).update_all(:active => false)
      AthleteTeam.where(:id => id).update_all(:active => true)
    end
  end
end
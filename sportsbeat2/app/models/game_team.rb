class GameTeam < ActiveRecord::Base
  belongs_to :game
  belongs_to :team

  validates :game_id, :presence => true
  validates :team_id, :presence => true
  validates_inclusion_of :home, :in => [true, false]
end

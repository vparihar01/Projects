class Score < ActiveRecord::Base
  belongs_to :game
  belongs_to :user

  validates :game, :presence => true
  validates :user, :presence => true
  validates :home_team_score, :presence => true
  validates :away_team_score, :presence => true
  validates_uniqueness_of :user_id, :scope => [:game_id]

  validate :game_unscored, :on => :create

  def self.confirmed?(game)
    game.scores.group('game_id, home_team_score, away_team_score').having('count(*) > 1').first
  end

  def game_unscored
    unless game && game.unscored?
      errors.add(:game, "is already scored")
    end
  end

  def same?(other)
    [:game_id, :home_team_score, :away_team_score].each do |sym|
      return false if self[sym] != other[sym]
    end

    return true
  end
end

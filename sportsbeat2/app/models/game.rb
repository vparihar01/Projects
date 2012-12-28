class Game < ActiveRecord::Base
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :away_team, :class_name => 'Team'
  belongs_to :winner, :class_name => 'Team', :foreign_key => 'winner_id'
  belongs_to :loser, :class_name => 'Team', :foreign_key => 'loser_id'
  has_many :game_teams, :dependent => :destroy
  has_many :scores, :dependent => :destroy
  has_many :teams, :through => :game_teams

  scope :scored, where('home_team_score IS NOT NULL AND away_team_score IS NOT NULL')
  scope :unscored, where('home_team_score IS NULL OR away_team_score IS NULL')
  scope :upcoming, where('datetime >= ?', DateTime.now)
  scope :previous, where('datetime < ?', DateTime.now)

  validates :home_team, :presence => true
  validates :away_team, :presence => true
  validates :season_id, :presence => true
  validates_uniqueness_of :datetime, :scope => [:home_team_id, :away_team_id]

  before_validation :assign_to_season, :on => :create 
  after_create :associate_teams

  def assign_to_season
    self.season_id = Season.find_id_by_date self.datetime
  end

  def associate_teams
    gt = GameTeam.new
    gt.team = home_team
    gt.game = self
    gt.home = true
    gt.save!

    gt = GameTeam.new
    gt.team = away_team
    gt.game = self
    gt.home = false
    gt.save!
  end

  def athletes
    Athlete.joins(:athlete_teams).where(:athlete_teams => {:team_id => [home_id, away_id], :season_id => season_id})
  end

  def display_name_for_team t
    # if t.id != home_team_id && t.id != away_team_id
    #   opp = away_team
    # else
    #   opp = my_opponent t
    # end

    # datestr = datetime.strftime("%m-%d-%Y")

    # if t.id == home_team_id
    #   homeaway = " vs. "
    # else
    #   homeaway = " @ "
    # end

    # name = t.school.short_name + homeaway + opp.school.short_name

    if t.id != home_team_id && t.id != away_team_id
      opp = away_team
    else
      opp = my_opponent t
    end

    if opp == away_team
      return "vs. #{opp.school.short_name}"
    else
      return "@ #{opp.school.short_name}"
    end
  end

  def enter_score score
    if unscored? && score.game_id == self.id
      self.home_team_score = score.home_team_score
      self.away_team_score = score.away_team_score
      self.set_winner_and_loser
      self.save!
    end
  end

  def latitude
    home_team.school.latitude
  end

  def longitude
    home_team.school.longitude
  end

  def my_opponent(my_team)
    if my_team.id == home_team_id
      away_team
    else
      home_team
    end
  end

  def my_team(user)
    if home_team.users.exists? user
      home_team
    elsif away_team.users.exists? user
      away_team
    else
      nil
    end
  end

  def over?
    !home_team_score.blank? && !away_team_score.blank?
  end

  def past?
    self.datetime < DateTime.now
  end

  def playing?(user)
    !athletes.where(:user_id => user.id).empty?
  end

  def set_winner_and_loser
    if self.home_team_score > self.away_team_score
      self.winner_id = self.home_team_id
      self.loser_id = self.away_team_id
      self.winner_score = self.home_team_score
      self.loser_score = self.away_team_score
    elsif away_team_score > self.home_team_score
      self.winner_id = self.away_team_id
      self.loser_id = self.home_team_id
      self.winner_score = self.away_team_score
      self.loser_score = self.home_team_score
    else
      self.winner_id = nil
      self.loser_id = nil
      self.winner_score = nil
      self.loser_score = nil
    end
  end

  def team_standing(team)
    if !over?
      "in progress"
    elsif home_team_score == away_team_score
      "tied"
    elsif team.id == self.winner_id
      "won"
    else
      "lost"
    end
  end

  def unscored?
    home_team_score.blank? || away_team_score.blank?
  end

  include Tire::Model::Callbacks
  include Tire::Model::Search
  include Search::ReloadHelper

  tire do
    mapping do
      indexes :id, :type => "integer"
      indexes :datetime, :type => "date"
      indexes :location, :type => "geo_point", :lat_lon => true
    end
  end

  def to_indexed_json
    {
      :id   => id,
      :datetime => datetime.utc.strftime("%FT%T.%3NZ"),
      :location => {
        :lat => latitude,
        :lon => longitude
      }
    }.to_json
  end
end

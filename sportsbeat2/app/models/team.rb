class Team < ActiveRecord::Base
  belongs_to :sport
  belongs_to :school

  has_many :athlete_teams, :dependent => :destroy
  has_many :athletes, :through => :athlete_teams
  has_many :users, :through => :athletes
  has_many :positions, :through => :sport
  has_many :game_teams, :dependent => :destroy
  has_many :games, :through => :game_teams

  validates :sport, :presence => true
  validates :school, :presence => true
  validates :level, :inclusion => {:in => ['varsity', 'jrvarsity', 'freshman']}
  validates :gender, :inclusion => {:in => ['m', 'w', 'mw']}
  validates_uniqueness_of :sport_id, :scope => [:school_id, :level, :gender]

  # def games
  #   Game.where("home_team_id = ? OR away_team_id = ?", self.id, self.id)
  # end

  def self.find_or_create team
    t = Team.where(:school_id => team.school_id, :sport_id => team.sport_id, :level => team.level, :gender => team.gender).first

    if t
      return t
    else
      team.save!
      return team
    end
  end

  def athlete_seasons
    athlete_teams.group(:season_id).order('season_id desc').pluck(:season_id)
  end

  def closest_game_to_now
    now = Time.zone.now
    future = games.upcoming.limit(1).order('date ASC').first
    past = games.previous.limit(1).order('date DESC').first

    if future.nil?
      return past
    elsif past.nil?
      return future
    else
      future_diff = (now - future.date).abs
      past_diff = (now - past.date).abs
      return future_diff <= past_diff ? future : past
    end
  end

  def display_name
    return case level
    when 'varsity' then 'Varsity'
    when 'jrvarsity' then 'Jr. Varsity'
    when 'freshman' then 'Freshman'
    else 'N/A'
    end
  end

  def display_name_with_sport
    display_name + ' ' + sport.name
  end

  def display_name_with_sport_and_gender
    gender_display_name + ' ' + display_name + ' ' + sport.name
  end

  def find_or_create_counterpart school
    conditions = {
      school_id: school.id,
      sport_id: self.sport_id,
      level: self.level,
      gender: self.gender
    }

    other = Team.where(conditions).first
    
    if other.nil?
      other = self.dup
      other.school = school
      other.save
    end

    return other
  end

  def game_seasons
    games.group(:season_id).order('season_id desc').pluck(:season_id)
  end

  def gender_display_name
    case gender
    when 'm' then return 'Boys\''
    when 'w' then return 'Girls\''
    when 'mw' then return '' #nothing kuz they asked
    end
  end

  def record
    record = {}

    self.games.scored.find_each do |g|
      if g.home_team_score == g.away_team_score
        record[g.season_id] ||= {}
        record[g.season_id]["ties"] ||= 0
        record[g.season_id]["ties"] += 1
      elsif g.winner_id == self.id
        record[g.season_id] ||= {}
        record[g.season_id]["wins"] ||= 0
        record[g.season_id]["wins"] += 1
      elsif g.loser_id == self.id
        record[g.season_id] ||= {}
        record[g.season_id]["losses"] ||= 0
        record[g.season_id]["losses"] += 1
      end
    end

    return record
  end

  def seasons
    return (athlete_seasons | game_seasons)
  end

  def short_name
    return case name
    when 'varsity' then 'V'
    when 'jrvarsity' then 'JV'
    when 'freshman' then 'F'
    else 'N/A'
    end
  end

  def short_name_with_sport_and_gender
    gender_display_name + ' ' + short_name + ' ' + sport.name
  end

end
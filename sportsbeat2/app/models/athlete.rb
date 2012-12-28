class Athlete < ActiveRecord::Base
  validates :school_id, :presence => true
  validates :final_year, :presence => true
  validate :validate_user_or_name

  belongs_to :user
  belongs_to :school
  has_many :athlete_teams, :dependent => :destroy
  has_many :teams, :through => :athlete_teams, :uniq => true

  def current_team
    at = current_athlete_team || athlete_teams.last || AthleteTeam.new
    return at.team
  end

  def current_athlete_team
    athlete_teams.where(:active => true).order('season_id desc').first
  end

  def current_positions
    at = current_athlete_team || athlete_teams.last || AthleteTeam.new
    return at.positions
  end

  def display_name
    if user
      user.display_name
    else
      first_name + " " + last_name
    end
  end

  def first_name
    if user
      user.first_name
    else
      self[:first_name]
    end
  end

  def graduated?
    final_year < Season.current
  end

  def import_teams_into_new_season season_id
    Athlete.transaction do
      ls_id = latest_season_id

      if season_id <= ls_id
        return false
      end

      current_ats = athlete_teams.where(:season_id => ls_id)
      current_ats.each do |at|
        new_at = at.dup
        new_at.position_ids = at.position_ids
        new_at.season_id = season_id
        new_at.save!
      end
    end

    return true
  end

  def join team, season_id = Season.current, active = false
    Athlete.transaction do
      at = AthleteTeam.new
      at.season_id = season_id
      at.team_id = team.id
      at.active = active
      self.athlete_teams << at
    end
  end

  def last_name
    if user
      user.last_name
    else
      self[:last_name]
    end
  end

  def latest_season_id
    athlete_teams.pluck('max(season_id)').first
  end

  def other_teams
    cat = current_athlete_team
    athlete_teams.includes(:team).where('id <> ?', cat.id).where(:season_id => cat.season_id).map(&:team)
  end

  def other_positions
    cat = current_athlete_team
    athlete_teams.where('id <> ?', cat.id).where(:season_id => cat.season_id).map(&:positions)
  end

  def ready_for_next_season?
    !graduated? && (latest_season_id < Season.current)
  end

  def season_ids
    season_ids = athlete_teams.select('distinct season_id').order('season_id desc').map(&:season_id)
  end

  def teammate_ids
    season_ids = athlete_teams.select('distinct season_id').map(&:season_id)
    team_ids = athlete_teams.select('distinct team_id').map(&:team_id)

    AthleteTeam.where(:season_id => season_ids, :team_id => team_ids).where('athlete_id <> ?', self.id).select('distinct athlete_id').map(&:athlete_id)
  end

  def validate_user_or_name
    if user.nil? && (first_name.nil? || last_name.nil?)
      errors.add :base, "Athlete must be associated with a user, or have a name"
    end
  end
end
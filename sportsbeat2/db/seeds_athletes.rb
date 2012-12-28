s1 = School.find(1)
s2 = School.find(27057)
t1 = Team.first
t2 = t1.find_or_create_counterpart s2

Athlete.transaction do
  User.athletes.find_each do |u|
    a = Athlete.new
    a.user = u
    a.school = [true, false].sample ? s1 : s2
    a.final_year = Season.current + rand(3)
    a.save!
  end

  User.alumni.find_each do |u|
    a = Athlete.new
    a.user = u
    a.school = [true, false].sample ? s1 : s2
    a.final_year = Season.current - 4 - rand(20)
    a.save!
  end
end

Athlete.transaction do
  Athlete.find_each do |a|
    latest_season = [a.final_year, Season.current].min
    seasons = (a.final_year-3)..latest_season

    seasons.each do |season|
      if a.school == s1
        a.join t1, season
      else
        a.join t1.find_or_create_counterpart(a.school), season
      end
    end

    position = t1.sport.positions.sample
    at = a.athlete_teams.first
    at.positions << position
  end
end

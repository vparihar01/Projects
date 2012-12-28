Team.transaction do
  team = Team.new
  team.school_id = 1 # SportsBeat High
  team.sport_id = 7 # Football
  team.level = "varsity"
  team.gender = "mw"
  team.save!

  team = team.dup
  team.school_id = 27057
  team.save!
end

# Game.transaction do
#   game = Game.new
#   game.home_team = Team.first
#   game.away_team = Team.last
#   game.datetime = DateTime.now
#   game.save!
# end

Game.transaction do
  base = DateTime.now.at_beginning_of_day + 12.hours
  ((base - 20.days)..(base + 10.days)).each do |dt|
    game = Game.new
    
    game.home_team = Team.first
    game.away_team = Team.last
    if [true, false].sample
      game.home_team, game.away_team = game.away_team, game.home_team
    end

    game.datetime = dt
    game.save!

    if game.datetime < base
      score = Score.new
      score.user_id = 2
      score.game = game
      
      score.home_team_score = 1
      score.away_team_score = 0
      if [true, false].sample
        score.home_team_score, score.away_team_score = score.away_team_score, score.home_team_score
      end
      
      game.enter_score score
    end
  end
end
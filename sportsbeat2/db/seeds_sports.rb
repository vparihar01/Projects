if Sport.count == 0
  Sport.transaction do
    sports = MultiJson.load Rails.root.join("db", "seed_data", "sports.json")
    sports.each do |hash|
      sport = Sport.new hash
      sport.save!
    end

    positions = MultiJson.load Rails.root.join("db", "seed_data", "positions.json")
    positions.each do |hash|
      position = Position.new hash
      position.save!
    end
  end
end
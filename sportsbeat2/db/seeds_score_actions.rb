if ScoreAction.count == 0
  json = File.read(Rails.root.join('db', 'seed_data', 'score_actions.json'))
  score_actions = JSON.parse(json)

  ScoreAction.transaction do
    score_actions.each do |hash|
      unless ScoreAction.where(:name => hash['name']).count > 0
        sa = ScoreAction.new
        sa.name = hash['name']
        sa.description = hash['description']
        sa.href = hash['href']
        sa.value = hash['value']
        sa.save!
      end
    end
  end
end
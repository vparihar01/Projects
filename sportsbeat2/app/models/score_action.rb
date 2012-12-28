class ScoreAction < ActiveRecord::Base
  FIRST_ACTIONS = %w(first_invite first_follow first_post first_profile_picture )

  validates :name, :presence => true
  validates_uniqueness_of :name
  validates :value, :presence => true

  def self.reload
    filename = Rails.root.join('db', 'seed_data', 'score_actions.json')
    json = File.read(filename)
    actions = JSON.parse(json)

    ScoreAction.transaction do
      actions.each do |hash|
        sa = ScoreAction.where(:name => hash['name']).first
        if sa.nil?
          sa = ScoreAction.new
          sa.name = hash['name']
          sa.description = hash['description']
          sa.href = hash['href']
          sa.value = hash['value']
        else
          sa.description = hash['description'] if sa.description != hash['description']
          sa.href = hash['href'] if sa.href != hash['href']
          sa.value = hash['value'] if sa.value != hash['value']
        end

        sa.save!
      end
    end
  end

  def self.first_action_names
    FIRST_ACTIONS
  end

  def self.uncompleted_first_actions user
    action_ids = ScoreAction.where(:name => FIRST_ACTIONS).select(:id).map(&:id)
    completed_action_ids = UserScore.where(:user_id => user.id, :score_action_id => action_ids).group(:score_action_id).select(:score_action_id).map(&:score_action_id)
    uncompleted_action_ids = action_ids - completed_action_ids
    ScoreAction.where(:id => uncompleted_action_ids)
  end

  def self.first_actions user
    ScoreAction.where(:name => FIRST_ACTIONS)
  end
end

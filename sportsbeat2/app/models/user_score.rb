class UserScore < ActiveRecord::Base
  MAX_PENDING_SCORES = 5

  belongs_to :user
  belongs_to :score_action

  validates :user_id, :presence => true
  validates :score_action_id, :presence => true
  validates :value, :presence => true

  before_destroy :decrement_score

  def self.add_score(user, score_action_name, immediate = false)
    sa = ScoreAction.where(:name => score_action_name).select('id, value').first

    UserScore.transaction do
      us = UserScore.create!(
        :user => user,
        :score_action => sa,
        :value => sa.value,
        :pending => !immediate)

      if immediate
        monthly = MonthlyScore.find_or_create_for(user, us.created_at.year, us.created_at.month)
        monthly.value = monthly.value + us.value
        monthly.save!

        check_for_complete_profile user
      elsif pending_batch_ready? user
        pending_batch_apply user
      end
    end
  end

  def self.add_score_immediately user, score_action_name
    add_score user, score_action_name, true
  end

  def self.check_for_complete_profile user
    if MonthlyScore.total_for(user) >= 100
      user.profile_complete = true
      user.save!
    end
  end

  def self.done_before? user, score_action_name
    sa = ScoreAction.where(:name => score_action_name).select(:id).first
    sa ? UserScore.where(:user_id => user.id, :score_action_id => sa.id).first : nil
  end

  def self.pending_batch_ready? user
    if !user.profile_complete
      return false
    end

    return UserScore.where(:user_id => user.id, :pending => true).count >= MAX_PENDING_SCORES
  end

  def self.pending_batch_apply user
    UserScore.transaction do
      last_year = 0
      last_month = 0
      monthly = nil

      UserScore.where(:user_id => user.id, :pending => true).each do |p|
        if last_year != p.created_at.year || last_month != p.created_at.month
          monthly.save! unless monthly.nil?

          last_year = p.created_at.year
          last_month = p.created_at.month
          monthly = MonthlyScore.find_or_create_for(user, last_year, last_month)
        end

        monthly.value = monthly.value + p.value
      end

      monthly.save! unless monthly.nil?
      UserScore.where(:user_id => user.id, :pending => true).update_all(:pending => false)
    end
  end

  private
  def decrement_score
    if !pending
      ms = MonthlyScore.where(:user_id => user_id, :year => created_at.year, :month => created_at.month).first
      unless ms.nil?
        ms.value = ms.value - self.value
        ms.save!
      end
    end
  end
end

class SalesTarget < ActiveRecord::Base
  belongs_to :sales_team

  # Ensure sales_team_id x year composite is unique
  class UniqueValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors[attribute] << "already exists for given sales team" if SalesTarget.where("sales_team_id = ? AND year = ? AND id != ?", record.sales_team_id, value, record.id.to_s).first
    end
  end

  validates :sales_team_id, :presence => true
  validates :year, :presence => true, :unique => true
  validates :amount, :numericality => true

end

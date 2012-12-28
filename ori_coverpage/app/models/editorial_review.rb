class EditorialReview < ActiveRecord::Base
  has_and_belongs_to_many :products, :uniq => true

  validates :source, :presence => true
  validates :body, :presence => true

  scope :ok, where("deleted_at IS NULL")
  
  def to_s
    if self.title.blank?
      if self.author.blank?
        self.source
      else
        "#{self.source} (#{self.author})"
      end
    else
      self.title
    end
  end
end

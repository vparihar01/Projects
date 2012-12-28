class FeedEntry < ActiveRecord::Base
  belongs_to :post

  validates :owner, :presence => true
  validates :name, :presence => true
  validates :iso8601, :presence => true

  before_validation :set_timestamp, :on => :create

  def self.entries_for ar, name, options = {}
    if ar.is_a?(String)
      owner = ar
    else
      owner = ar.class.table_name + ":" + ar.id.to_s
    end

    entries = FeedEntry.where(:owner => owner, :name => name)

    if options[:newer_than]
      entries = entries.where("iso8601 > ?", options[:newer_than])
    end

    if options[:older_than]
      entries = entries.where("iso8601 < ?", options[:older_than])
    end

    return entries.order("iso8601 desc")
  end

  def owner= ar
    write_attribute(:owner, ar.class.table_name + ":" + ar.id.to_s)
  end

  def set_timestamp
    if !iso8601
      self.iso8601 = Time.now.utc.iso8601(9)
    end
  end
end

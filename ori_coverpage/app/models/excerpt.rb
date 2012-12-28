class Excerpt < ActiveRecord::Base
  PATH_PREFIX = (defined?(Rails) && !Rails.blank? && !Rails.env.blank? && Rails.env == 'test') ? 'public/../tmp/' : 'public/../'  # if testing, write to tmp otherwise bad things will happen to files in protected/excerpts
  has_attachment :content_type => 'application/pdf', :storage => :file_system, :path_prefix => "#{PATH_PREFIX}protected/excerpts"
  has_ipaper_and_uses 'AttachmentFu'
  belongs_to :title
  validates :title_id, :presence => true, :uniqueness => true
  # TODO: uncommenting this causes "Validation failed: Size is not included in the list" error
  # validates_as_attachment
  after_save :update_ipaper_settings, :if => "self.class.callback_switch"
  
  cattr_accessor :callback_switch
  self.callback_switch = true

  def exist?
    File.exist?(self.full_filename)
  end
  
  def mtime
    if self.exist?
      File.stat(self.full_filename).mtime
    else
      nil
    end
  end
  
  def update_ipaper_settings
    doc = self.ipaper_document
    title = self.reload.title
    unless doc.nil? || title.nil?
      doc.title = title.name
      doc.author = title.author
      doc.description = title.description
      doc.publisher = title.publisher
      doc.when_published = title.available_on
      doc.tags = title.assemblies.map{|a| a.categories.map(&:name)}.flatten.uniq.join(",")
      doc.license = "c" # Traditional copyright: all rights reserved
      doc.save
    end
  end
  
end

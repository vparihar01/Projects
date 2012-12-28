class Download < ActiveRecord::Base
  acts_as_taggable
  include TaggableModelMethods
  PATH_PREFIX = (defined?(Rails) && !Rails.blank? && !Rails.env.blank? && Rails.env == 'test') ? 'tmp/' : ''  # if testing, write to tmp otherwise bad things will happen to files in protected/downloads
  has_attachment :storage => :file_system, :path_prefix => "#{PATH_PREFIX}protected/downloads"

  validates :title, :presence => true
  validates :description, :presence => true
  # validates_as_attachment
  validates :size, :presence => true
  validates :filename, :presence => true    # TODO: validates_as_attachment causes error with 'rename' method
  
  FILE_TYPES = {'txt' => 'Text', 'xls' => 'Excel'}
  
  # add 1 to the views count
  def mark_as_viewed
  	self.views += 1
  	self.save( :validate => false )  # no need to perform validations in this case
  end
  
  def exist?
    File.exist?(self.public_filename)
  end
  
  def mtime
    if self.exist?
    	File.stat(self.public_filename).mtime
  	else
	    nil
	  end    
  end
  
  def file_type
    ext = self.filename.split('.').last.downcase
    FILE_TYPES.has_key?(ext) ? FILE_TYPES[ext] : ext.upcase
  end
  
  def rename(new_name, old_path=self.public_filename)
    File.rename(old_path, File.join(File.dirname(old_path), sanitize_filename(new_name))) if self.update_attributes( :filename => new_name )
  end

  def sanitize_filename(name)
    # get only the filename, not the whole path and
    # replace all none alphanumeric, underscore or periods with underscore
    File.basename(name.gsub('\\', '/')).gsub(/[^\w\.\-]/,'_') 
  end
  
end

class Handout < ActiveRecord::Base
  belongs_to :teaching_guide
  mount_uploader :document, DocumentUploader

  validates :name, :presence => true
  validates_presence_of :document

  def to_s
    self.name
  end

  # Increment the download counter
  def mark_as_downloaded
  	self.download_counter += 1
  	self.save(:validate => false)  # no need to perform validations in this case
  end

  def document_ext
    unless self.document.file.empty?
      File.extname(self.document.file.identifier).gsub(/^\./, '')
    end
  end

  def document_exist?
    if self.document.file && !self.document.file.empty?
      File.exist?(self.document.current_path)
    else
      false
    end
  end

  def document_path
    if self.document.file && !self.document.file.empty?
      self.document.current_path.gsub(/^#{Rails.root}\//, '')
    else
      false
    end
  end

end

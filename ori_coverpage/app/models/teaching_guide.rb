class TeachingGuide < ActiveRecord::Base
  acts_as_taggable
  include TaggableModelMethods

  has_and_belongs_to_many :products
  belongs_to :interest_level_min, :class_name => "Level"
  belongs_to :interest_level_max, :class_name => "Level"
  has_many :handouts
  mount_uploader :document, DocumentUploader

  validates :name, :presence => true
  validates :body, :presence => true

  def to_s
    self.name
  end

  def self.to_dropdown
    order(:name).all.map {|handout| [handout.name, handout.id]}
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

  def categories
    self.category.split(",")
  end

  def objectives
    self.objective.split("\r\n")
  end

  def interest_level_range
    [self.interest_level_min.try(:name), self.interest_level_max.try(:name)].compact.join(' - ')
  end

  def self.create_with_local_file(*args)
    data = args.extract_options!.symbolize_keys
    path = data.delete(:path)
    mimetype = data.delete(:mimetype)
    if file = Rack::Test::UploadedFile.new(path, mimetype)
      self.create(data.merge(:document => file))
    else
      logger.error "Error: File not created"
    end
  end

  def update_with_local_file(*args)
    data = args.extract_options!.symbolize_keys
    path = data.delete(:path)
    mimetype = data.delete(:mimetype)
    if file = Rack::Test::UploadedFile.new(path, mimetype)
      self.update_attributes(data.merge(:document => file))
    else
      logger.error "Error: File not created"
    end
  end

end

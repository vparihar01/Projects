class Title < Product
  has_many :assembly_assignments, :foreign_key => 'product_id', :dependent => :destroy
  has_many :assemblies, :through => :assembly_assignments, :order => :name
  has_one :excerpt, :dependent => :destroy
  has_one :download, :class_name => "ProductDownload"
  belongs_to :collection

  # A Title is its own sample
  def sample
    self
  end
  
  def name_for_dropdown
    self.collection ? "#{self.name} (#{self.collection.name})" : "#{self.name}"
  end
  
  def create_download_with_local_file(path)
    apply_metadata(path)
    data = Rack::Test::UploadedFile.new(path, "application/pdf")
    if download = self.download
      logger.info "Overwriting product download..."
      download.update_attributes!(:uploaded_data => data, :title_id => self.id, :updated_at => Time.now)
    else
      logger.info "Adding product download..."
      download = ProductDownload.new(:uploaded_data => data, :title_id => self.id)
      download.save!
    end
    logger.debug("product_download title_id --- #{download.title_id.inspect}")
    logger.debug("product_download filename --- #{download.filename.inspect}")
  end

  def create_excerpt_with_local_file(path)
    if /^rand/.match(File.basename(path))
      logger.info "Renaming '#{path}' by ISBN..."
      new_path = File.join(File.dirname(path), "#{self.isbn}.pdf")
      unless File.exist?(new_path)
        File.mv(path, new_path)
        path = new_path
      else
        logger.info "! Error: '#{new_path}' already exists"
      end
    end
    data = Rack::Test::UploadedFile.new(path, "application/pdf")
    if self.excerpt
      logger.info "Destroying old excerpt..."
      self.excerpt.destroy
    end
    logger.info "Creating new excerpt..."
    self.excerpt = Excerpt.create(:uploaded_data => data, :title_id => self.id)
    logger.debug("excerpt id --- #{excerpt.id.inspect}")
    logger.debug("excerpt title_id --- #{excerpt.title_id.inspect}")
    logger.debug("excerpt filename --- #{excerpt.filename.inspect}")
    logger.debug("excerpt ipaper_id --- #{excerpt.ipaper_id.inspect}")
  end
  
  def subjects
    self.assemblies.map{|a| a.categories.map(&:name)}.flatten.uniq
  end
  
  # overriding Product::save_uploaded_file due to the ":product" attribute in the original...
  def save_uploaded_file
    return unless @uploaded_data
    @download = self.download || self.build_download
    @download.update_attributes(:uploaded_data => @uploaded_data, :title => self)
  end

  # Deprecated: pdftk fails to update metadata
  # def create_ebook_metadata_file
  #   path = Rails.root.join("tmp", "#{self.isbn}.txt")
  #   # Option 'w' will overwrite a pre-existing file
  #   File.open(path, 'w') do |f|
  #     f.write("InfoKey: Title\n")
  #     f.write("InfoValue: #{self.name}\n")
  #     f.write("InfoKey: Author\n")
  #     f.write("InfoValue: #{self.author}\n")
  #   end
  #   path
  # end

  def apply_metadata(path)
    # path should be a file path string or a Pdf instance (see lib/pdf.rb)
    pdf = path.is_a?(Pdf) ? path : Pdf.new(path.to_s)
    pdf.apply_metadata(:title => self.name, :author => self.author)
  end

  def chapters
    if self.toc.blank?
      []
    else
      self.toc.split("\n")
    end
  end
end

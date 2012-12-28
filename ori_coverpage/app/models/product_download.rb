require 'lib/pdf_tool'
class ProductDownload < ActiveRecord::Base
  belongs_to :title

  PATH_PREFIX = (defined?(Rails) && !Rails.blank? && !Rails.env.blank? && Rails.env == 'test') ? 'tmp/' : ''  # if testing, write to tmp otherwise bad things will happen to files in protected/uploads
  has_attachment :content_type => 'application/pdf', :storage => :file_system, :path_prefix => "#{PATH_PREFIX}protected/ebooks"
    
  validates :content_type, :presence => true
  validates :filename, :presence => true
  validates :title_id, :presence => true, :uniqueness => true
  after_save :create_excerpt, :if => "self.class.callback_switch"
  
  cattr_accessor :callback_switch
  self.callback_switch = true
  
  include PdfTool
  
  def create_excerpt
    logger.info "Generating product download excerpt..."
    logger.debug("ebook filename --- #{self.full_filename.inspect}")

    # generate an extract of the original pdf
    epdf = PdfBlender.new(:source => self.full_filename)
    logger.debug("extract pdf blender instantiated for the ebook...")
    pages_filename = epdf.extract(epdf.get_page_array(CONFIG[:pdftool_sample_front_pages], CONFIG[:pdftool_sample_back_pages]))
    logger.debug("pages in: #{pages_filename}")

    # add watermark to extract
    extract_filename = Rails.root.join(CONFIG[:pdftool_temp_dir], "#{self.title.isbn}.pdf")
    logger.debug("attempting to create extract: #{extract_filename}")
    spdf = PdfBlender.new(:source => pages_filename, :target => extract_filename, :overwrite => true, :text_properties => CONFIG[:pdftool_sample_text_properties])
    logger.debug("main extract created, optional watermarking: #{"todo"}")
    waterfile = CONFIG[:pdftool_sample_watermark_file].blank? ? nil : Rails.root.join(CONFIG[:pdftool_sample_watermark_file])
    extract_filename = spdf.watermark(waterfile, CONFIG[:pdftool_sample_text])

    # create excerpt record in database
    if File.exists?(extract_filename)
      self.title.create_excerpt_with_local_file(extract_filename)
    else
      logger.info "Error! Extract file ""#{extract_filename}"" is missing..."
    end
  end
  
  def watermark_for_user(user)
    logger.info "Watermarking product download for #{user.email || user.name}..."

    # substitute user data into watermark text string, if defined
    unless CONFIG[:pdftool_download_text].blank?
      text = sprintf(CONFIG[:pdftool_download_text], user.email || user.name)
    else
      text = nil
    end

    # apply watermark file and personalized watermark text to product download
    blender = PdfBlender.new(:source => self.full_filename, :text_properties => CONFIG[:pdftool_download_text_properties])
    download_filename = blender.watermark( (CONFIG[:pdftool_download_watermark_file].blank? ? nil : Rails.root.join(CONFIG[:pdftool_download_watermark_file])), text )
    
    # secure personalized, watermarked file
    unless CONFIG[:pdftool_download_password].blank?
      blender = PdfBlender.new(:source => download_filename, :target => Rails.root.join(CONFIG[:pdftool_temp_dir], "#{self.title.sanitize_name.slice(0,30)}_sec_wm_#{user.id}.pdf"), :owner_pw => CONFIG[:pdftool_download_password], :permissions => CONFIG[:pdftool_download_permissions])
      secure_filename = blender.secure
    else
      # move the random filename away to a meaningful name
      final_filename = Rails.root.join(CONFIG[:pdftool_temp_dir], "#{self.title.sanitize_name.slice(0,30)}_wm_#{user.id}.pdf")
      FileUtils.mv( download_filename, final_filename )
      # and return that filename, just like when securing, we have a nice name, not a random one
      final_filename
    end
  end
  
  def exist?
    File.exist?(self.public_filename)
  end
  
end

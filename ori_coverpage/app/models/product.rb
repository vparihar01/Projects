require 'pdf'
class Product < ActiveRecord::Base
  include CounterCache

  TYPES = {'Product' => 'All', 'Title' => 'Title', 'Assembly' => 'Set'}.freeze
  SUBTYPES = TYPES.dup.delete_if{|k,v| k == self.to_s}.to_a.inject({}) {|h,e| h[e[1]] = e[0]; h}.freeze
  SELECT_PARTIALS = Dir.glob("#{Rails.root.join("app/views/admin/products")}/_by_*").map{|f| File.basename(f).sub(/^_(.+?)\.(.+)/, '\1')}.freeze
  SEARCHABLE_FIELDS = %w(name_contains description_contains product_formats_isbn_in author_contains bisac_subjects_code_in copyright_from copyright_to alsreadlevel_from alsreadlevel_to type_in lexile_from lexile_to guided_level_in dewey_in dewey_to dewey_from available_on catalog_page_in interest_level_to interest_level_from reading_level_from reading_level_to product_formats_format_id_equals product_formats_status_in)
  FILTER_COPYRIGHT_RANGE = [Product.minimum(:copyright), Date.today.year].freeze # Must be restarted at beginning of year
  FILTER_ALSREADLEVEL_RANGE = [Product.minimum(:alsreadlevel).try(:floor).try(:to_i), Product.maximum(:alsreadlevel).try(:ceil).try(:to_i)].freeze
  FILTER_LEXILE_RANGE = [Product.minimum(:lexile).try(:floor).try(:to_i), Product.maximum(:lexile).try(:ceil).try(:to_i)].freeze
  SEASONS = ['new', 'upcoming', 'recent', 'active', 'current', 'backlist', 'all'].sort.freeze

  versioned
  
  belongs_to :collection
  has_and_belongs_to_many :categories, :uniq => true, :order => "name"
  has_many :posted_transaction_lines
  has_many :posted_transactions, :through => :posted_transaction_lines
  has_and_belongs_to_many :links, :uniq => true
  has_and_belongs_to_many :editorial_reviews, :uniq => true, :order => "written_on DESC"
  has_and_belongs_to_many :teaching_guides
  has_many :contributor_assignments, :order => :role, :dependent => :destroy
  has_many :contributors, :through => :contributor_assignments, :order => :name
  has_many :formats, :through => :product_formats, :order => 'format_id'
  has_many :product_formats, :order => 'format_id'
  has_many :line_items, :through => :product_formats
  has_many :active_formats, :class_name => "ProductFormat", :conditions => ["status = ?", ProductFormat::ACTIVE_STATUS_CODE], :order => 'format_id'
  has_one :default_format, :class_name => "ProductFormat", :order => 'format_id' # TODO: This should be associated to library format not first format by id
  has_one :pdf_format, :class_name => "ProductFormat", :conditions => "format_id = #{Format::PDF_ID}"
  has_one :trade_format, :class_name => "ProductFormat", :conditions => "format_id = #{Format::TRADE_ID}"
  has_many :errata, :through => :product_formats
  has_many :price_changes, :through => :product_formats
  has_many :bisac_assignments, :dependent => :destroy
  has_many :bisac_subjects, :through => :bisac_assignments
  has_many :related_product_assignments, :order => :relation, :dependent => :destroy
  has_many :related_products, :class_name => "Product", :through => :related_product_assignments, :order => :name
  has_many :similar_products, :class_name => "Product", :through => :related_product_assignments, :order => :name, :conditions => ["related_product_assignments.relation = ?", RelatedProductAssignment::SIMILAR_ID]
  belongs_to :interest_level_min, :class_name => "Level"
  belongs_to :interest_level_max, :class_name => "Level"
  belongs_to :reading_level, :class_name => "Level"

  before_save :calculate_title_and_subtitle
  after_save :save_uploaded_file

  attr_accessor :uploaded_data

  # counter_cache call must appear after association definitions
  counter_cache :collection, :available_products_counter, lambda {|p| p.available?}

  def self.select_partials_dropdown(options = {})
    list = SELECT_PARTIALS.map{|x| [x.sub(/^by_/, '').titlecase, x]}
    list.insert(0, '') if options[:include_blank] == true
    list
  end

  def self.seasons_dropdown(options = {})
    list = SEASONS
    list.insert(0, '') if options[:include_blank] == true
    list
  end

  def self.find_using_options(options = {})
    options.symbolize_keys!
    FEEDBACK.debug("Product.find_using_options")
    FEEDBACK.debug("options = #{options.inspect}")
    case options[:product_select]
    when "by_date"
      available_between(options[:start_date], options[:end_date])
    when "by_season"
      start_date, end_date = Coverpage::Utils.season_to_dates(options[:season])
      available_between(start_date, end_date)
    when "by_isbn"
      if options[:isbns].is_a?(String)
        isbns = options[:isbns].split(',').map{|i| i.strip}
      elsif options[:isbns].is_a?(Array)
        isbns = options[:isbns]
      else
        isbns = nil
      end
      join_formats_with_distinct.where("product_formats.isbn IN (?)", isbns)
    when "by_id"
      if options[:ids].is_a?(String)
        ids = options[:ids].split(',').map{|i| i.strip}
      elsif options[:ids].is_a?(Array)
        ids = options[:ids]
      else
        ids = nil
      end
      where(:id => ids)
    else
      Rails.logger.debug("# DEBUG: unrecognized 'product_select' value -- use product class")
      self.all
    end
  end

  # Publishing periods start 1 Jan and 1 Aug. 
  # Products are New if released in the current period 
  # Products are Recent if released in the previous period
  # Products are Upcoming if they will be released in the next period
  def self.new_on
    Time.now.month >= 8 ? Date.new(Time.now.year, 8, 1) : Date.new(Time.now.year, 1, 1)
  end
  
  def self.recent_on
    Time.now.month >= 8 ? Date.new(Time.now.year, 1, 1) : Date.new(Time.now.year - 1, 8, 1)
  end
  
  def self.upcoming_on
    Time.now.month >= 8 ? Date.new(Time.now.year + 1, 1, 1) : Date.new(Time.now.year, 8, 1)
  end
  
  def self.backlist_on
    self.new_on - 1.year
  end

  # The date ALS data is expected (Oct 15 and Mar 15 of each year)
  def self.pending_on
     Date.today >= Date.new(Time.now.year, 10, 15) ? ' Pending (Expected on 3/15/' + (Time.now.year + 1).to_s + ')' : ( Date.today >= Date.new(Time.now.year, 3, 15) ? ' Pending (Expected on 10/15/' + Time.now.year.to_s + ')' : ' Pending (Expected on 3/15/' + Time.now.year.to_s + ')' )
  end

  def self.new_season
     Time.now.month >= 8 ? 'Fall ' + Time.now.year.to_s : 'Spring ' + Time.now.year.to_s
  end 

  def self.recent_season
     Time.now.month >= 8 ? 'Spring ' + Time.now.year.to_s : 'Fall ' + (Time.now.year - 1).to_s
  end
  
  def self.upcoming_season
     Time.now.month >= 8 ? 'Spring ' + (Time.now.year + 1).to_s : 'Fall ' + Time.now.year.to_s
  end
  
  scope :join_formats_with_distinct, lambda { 
    select("DISTINCT products.*").includes(:product_formats)
  }
  scope :default_format, includes(:product_formats).where("product_formats.format_id = '#{Format::DEFAULT_ID}'")
  scope :pdf_format, includes(:product_formats).where("product_formats.format_id = '#{Format::PDF_ID}'")
  scope :trade_format, includes(:product_formats).where("product_formats.format_id = '#{Format::TRADE_ID}'")
  scope :active, includes(:product_formats).where("product_formats.status = '#{ProductFormat::ACTIVE_STATUS_CODE}'")
  scope :available, where("available_on <= NOW()")
  scope :newly_available, where("available_on <= NOW() AND available_on >= '#{self.new_on}'")
  scope :recently_available, where("available_on < '#{self.new_on}' AND available_on >= '#{self.recent_on}'")
  scope :upcoming, where("available_on > NOW() AND available_on <= '#{self.upcoming_on}'")
  scope :available_between, lambda { |start_date, end_date| 
    {:conditions => (start_date.blank? && end_date.blank? ? '' : (start_date.blank? ? ["available_on <= ?", end_date] : (end_date.blank? ? ["available_on >= ?", start_date] : ["available_on >= ? AND available_on <= ?", start_date, end_date])))}
  }
  scope :grade, lambda { |level| 
    where( level.blank? ? '' : ["interest_level_min_id <= ? AND interest_level_max_id >= ?", level.to_i+2, level.to_i+2] )
  }
  scope :spotlighted, where("is_spotlight = ?", true)
  
  def suggested_replacement
    product = self.class.includes(:product_formats).where('products.available_on <= CURRENT_DATE AND products.available_on >= ? AND products.name = ?', self.available_on, self.name).order('available_on DESC, proprietary_id DESC').first
    if product && product.id != self.id && product.default_format.status == ProductFormat::ACTIVE_STATUS_CODE
      product
    else
      nil
    end
  end

  def replacement
    self.related_products.where('related_product_assignments.relation = ?', RelatedProductAssignment::REPLACED_ID).first
  end

  def replace_with(new_product, options = {})
    return false unless new_product
    if new_product.available_on > Date.today
      FEEDBACK.error("New product (#{new_product.id}) is not available (#{new_product.available_on}).")
    elsif self.available_on > new_product.available_on
      FEEDBACK.error("Old product (#{self.id}) is newer than new product (#{new_product.id}).")
    elsif new_product.default_format.status != ProductFormat::ACTIVE_STATUS_CODE && !options[:force]
      FEEDBACK.warning("New product is not Active (#{new_product.default_format.status}). Try: option 'force'.")
    else
      FEEDBACK.verbose("Assigning new product (#{new_product.id}) as replacement to old product (#{self.id})...") if options[:verbose]
      if rpa = RelatedProductAssignment.find_by_product_id_and_relation(self.id, RelatedProductAssignment::REPLACED_ID)
        FEEDBACK.verbose("  Updating pre-existing related product assignment (#{rpa.id})...") if options[:verbose]
        rpa.related_product_id = new_product.id
      else
        rpa = RelatedProductAssignment.new(:product_id => self.id, :relation => RelatedProductAssignment::REPLACED_ID, :related_product_id => new_product.id)
      end
      unless result = options[:debug] ? true : rpa.save
        rpa.errors.full_messages.each do |error|
          FEEDBACK.error("#{error}")
        end
      end
      if result
        FEEDBACK.verbose("Processing old product formats...") if options[:verbose]
        self.product_formats.each do |pf|
          FEEDBACK.verbose("  #{pf.to_s} (#{pf.id}): Changing status from '#{pf.status}' to '#{ProductFormat::REPLACED_STATUS_CODE}'...") if options[:verbose]
          pf.update_attribute(:status, ProductFormat::REPLACED_STATUS_CODE) unless options[:debug]
        end
      end
    end
  end

  def suggested_similarities
    if result = /^(.+):/.match(self.name)
      products = self.class.where("name LIKE ? AND id != ?", "#{result[1]}%", self.id)
    else
      products = self.class.where("name LIKE ? AND id != ?", "#{self.name}%", self.id)
    end
  end

  def similar_to(another_product, options = {})
    self.relate_to(another_product, RelatedProductAssignment::SIMILAR_ID, options)
    another_product.relate_to(self, RelatedProductAssignment::SIMILAR_ID, options)
  end

  def relate_to(another_product, relation, options = {})
    FEEDBACK.verbose("Relating product (#{another_product.id}) to product (#{self.id}) as #{relation}...") if options[:verbose]
    rpa = RelatedProductAssignment.new(:product_id => self.id, :relation => relation, :related_product_id => another_product.id)
    unless result = options[:debug] ? true : rpa.save
      rpa.errors.full_messages.each do |error|
        FEEDBACK.error("#{error}")
      end
    end
  end
  
  def unreplace(options = {})
    FEEDBACK.verbose("Deleting related product assignment...") if options[:verbose]
    if rpa = RelatedProductAssignment.where(:product_id => self.id, :relation => RelatedProductAssignment::REPLACED_ID).first
      rpa.destroy unless options[:debug]
      if options[:status]
        FEEDBACK.verbose("Processing product formats...") if options[:verbose]
        self.product_formats.each do |pf|
          FEEDBACK.verbose("  #{pf.to_s} (#{pf.id}): Changing status from '#{pf.status}' to '#{options[:status].upcase}'...") if options[:verbose]
          pf.update_attribute(:status, options[:status].upcase) unless options[:debug]
        end
      end
    end
  end
  
  # Return random list of new titles
  def self.find_random_new(i)
    newly_available.spotlighted.order("RAND()").limit(i)
  end
  
  # Preferred custom sort by collection name then product name
  def self.find_sorted(*args)
    with_scope(:find => select('*, @collection_id := (IF(STRCMP(type, "Assembly")=0,id,collection_id)), @collection_name := (select name from collections where id=@collection_id), CONCAT(ifnull(@collection_name,""), name) as custom_sort_order').order("custom_sort_order")) { find(*args) }
  end
  
  def self.purchased_by(customer_id, options = {})
    self.select("products.*, sum(if(pt.customer_id = #{customer_id},ptl.quantity,0)) as quantity_sold, c.name as collection_name").
      joins("inner join collections c on (products.collection_id = c.id)
            left join posted_transaction_lines ptl on (products.id = ptl.product_id)
            left join posted_transactions pt on (ptl.posted_transaction_id = pt.id and pt.customer_id = #{customer_id})
            left join categories_products cp on (c.id = cp.product_id)").group('products.id').order('products.name') #.merge(options))
  end
  
  def self.find_latest(*args)
    with_scope :find => order('available_on desc') do
      all.find(*args)
    end
  end
  
  def self.find_by_isbn(isbn)
    self.includes(:product_formats).where("product_formats.isbn = ?", isbn.to_s.gsub('-', '')).first(:readonly => false)
  end
  
  def self.find_by_isbn_and_name(isbn, name)
    self.includes(:product_formats).where("product_formats.isbn = ?", isbn.to_s.gsub('-', '')).where("products.name = ?", name).first(:readonly => false)
  end

  # Return a string identifying the release date of the product
  def list_status
    if self.available_on.nil?
      nil
    elsif self.tba?
      'TBA'
    elsif self.upcoming?
      'Upcoming'
    elsif self.new?
      'New'
    elsif self.recent?
      'Recent'
    elsif self.backlist?
      'Backlist'
    else
      nil
    end
  end
  
  # Product available after 'upcoming_on' date
  def tba?
    (!self.available_on.nil? && self.available_on > self.class.upcoming_on)
  end

  # Product available after today and before 'upcoming_on' date
  def upcoming?
    (!self.available_on.nil? && self.available_on > Date.today && self.available_on <= self.class.upcoming_on)
  end
  
  # Product available before today and after 'new_on' date
  def new?
    (!self.available_on.nil? && self.available_on >= self.class.new_on && self.available_on <= Date.today)
  end
  
  # Product available between 'new_on' date and 'recent_on' date
  def recent?
    (!self.available_on.nil? && self.available_on >= self.class.recent_on && self.available_on < self.class.new_on)
  end
  
  # Product available before 'recent_on' date
  def backlist?
    (!self.available_on.nil? && self.available_on < self.class.recent_on)
  end
  
  # Product available before today
  def available?
    (!self.available_on.nil? && self.available_on <= Date.today)
  end

  # generates images for the website into the CONFIG[:website_images_dir]'s subdirectory, according to the image type and size
  # requires the ebook PDF file to be present
  # overwrites pre-existing images
  #
  # input parameters:
  # <tt>type</tt>   the image type covers/spreads (currently only 'covers' is implemented)
  # <tt>size</tt>   the image size s/m/l (see IMAGE_SIZE_GEOMETRIES)
  #
  # returns the relative (to Rails.root/CONFIG[:website_images_dir])
  #
  # ==================================================================
  # IMPORTANT: commented out because uses RMagick gem which hogs memory
  # ==================================================================
  #
  # def generate_image(type = "covers", size = "s")
  #   # for now we only generate covers
  #   # TODO comment next line once spreads are implemented (check w/ Tim what spreads should be)
  #   type = "covers"
  #   file_web = web_image_path(type, size)
    
  #   file_path = "no-photo.gif"       # default return value (in case an image can not be generated
  #   if self.respond_to?('download') && !self.download.nil?         # if we have a download
  #     thumb_filename =  Rails.root.join(CONFIG[:website_images_dir], file_web)   # construct thumbnail file path (full path)
  #     if File.exist?(self.download.full_filename)                                   # check that ebook file exists
  #       thumb_pdf = PdfBlender.new(:source => self.download.full_filename, :target => thumb_filename)   # define PDF transformation
  #       # TODO in case it's not the first page we should generate the thumbnail from, change it here - or move it to the environment as some variable
  #       thumb_pdf.thumb("1", CONFIG[:website_image_size_geometries][size])
  #       file_path = file_web unless !File.exist?(thumb_filename)
  #     end
  #   end
  #   file_path
  # end

  def generate_image_from_ebook_file(source_file = "", type = "covers", target_dir = CONFIG[:image_archive_dir], options = {})
    unless File.exist?(source_file)
      FEEDBACK.error("Source file does not exist #{source_file}")
      return false
    end
    pdf = Pdf.new(source_file, options)
    base = File.join(type, "#{self.isbn}.jpg")
    target_file = File.join(target_dir, base)
    unless File.exist?(target_file) && options[:force] != true
      FEEDBACK.verbose "  Creating #{base}..."
      FEEDBACK.debug "pdf.send(#{type.singularize}, #{target_file}, #{options.inspect})"
      pdf.send(type.singularize, target_file, options) unless options[:debug]
    else
      FEEDBACK.verbose "  Skipping: Target file exists '#{target_file}'"
      return false
    end
    target_file
  end
  
  def generate_image(type = "covers", target_dir = CONFIG[:image_archive_dir], options = {})
    unless self.respond_to?('download') && !self.download.nil?
      FEEDBACK.debug("Product download does not exist")
      return false
    end
    source_file = self.download.full_filename
    unless File.exist?(source_file)
      FEEDBACK.error("Product download missing")
      return false
    end
    generate_image_from_ebook_file(source_file, type, target_dir, options)
  end

  def generate_images(target_dir = CONFIG[:image_archive_dir], options = {})
    %w(covers spreads).each do |type|
      generate_image(type, target_dir, options)
    end
  end

  def web_image_path(type = "covers", size = "s")
    type = "covers" if ! /^(covers|spreads)$/.match(type)
    size = "s" if ! /^(s|m|l)$/.match(size)
    sub_dir = "#{type}/#{size}"
    file_ext = ".jpg"
    file_name = self.isbn.to_s + file_ext
    file_web = File.join(sub_dir, file_name)
  end
  
  def has_image?(type = "covers", size = "s")
    file_web = web_image_path(type, size)
    File.exist?(Rails.root.join(CONFIG[:website_images_dir], file_web)) ? file_web : nil
  end
  
  def has_cover?(size = "s")
    has_image?("covers", size)
  end
  
  def has_spread?(size = "s")
    has_image?("spreads", size)
  end
  
  def is_wide?
    self.default_format && self.default_format.width.to_f >= 9
  end

  # returns the website image (cover or spread) for the product
  # if not exist, it will attempt to generate it
  def image(type = "covers", size = "s")
    file_web = has_image?(type, size)
    # TODO Add CONFIG key that is checked here 
    # to determine if image should be generated when not pre-existent
    # file_web.nil? ? self.generate_image(type, size) : file_web
    file_web || "no-photo.gif"
  end

  def cover_image_width(size = "s")
    size = "s" if ! /^(s|m|l)$/.match(size)
    (self.default_format.width*150*CONFIG["website_image_scale_#{size}".to_sym]).round
  end

  def cover_image_height(size = "s")
    size = "s" if ! /^(s|m|l)$/.match(size)
    (self.default_format.height*150*CONFIG["website_image_scale_#{size}".to_sym]).round
  end

  def delete_web_images(options = {})
    %w(covers spreads).each do |type|
      %w(s m l).each do |size|
        image = Rails.root.join(CONFIG[:website_images_dir], type, size, "#{self.isbn}.jpg")
        FileUtils.rm(image, :noop => options[:debug], :verbose => options[:verbose]) if File.exist?(image)
      end
    end
  end

  def delete_archive_images(type = "covers", options = {})
    allowable_types = %w(covers spreads)
    return false unless allowable_types.include?(type)
    # format should contain jpg, tif, eps or the like
    format = options[:format].blank? ? "*" : options[:format]
    images = Dir.glob(File.join(CONFIG[:image_archive_dir], type, "#{self.isbn}.#{format}"))
    images.each do |image|
      FileUtils.rm(image, :noop => options[:debug], :verbose => options[:verbose])
    end
  end
  
  def name_less_article
    self.name ? self.name.gsub(/^(A|An|The) /i, '') : ''
  end

  def interest_level_range(options = {})
    attribute = options[:abbreviation] == true ? 'abbreviation' : 'name'
    [self.interest_level_min.try(attribute), self.interest_level_max.try(attribute)].compact.join(' - ')
  end
  
  def save_uploaded_file
    return unless @uploaded_data
    @download = self.download || self.build_download
    @download.update_attributes(:uploaded_data => @uploaded_data, :product => self)
  end
  
  # returns 1 if product has an alsquiznr (not null), 0 otherwise
  def alsquiz_count
    self.alsquiznr.nil? ? 0 : 1
  end
  
  def default_price_list
    self.default_format ? self.default_format.price_list : nil
  end
  
  def default_price
    self.default_format ? self.default_format.price : nil
  end

  def isbn
    self.default_format ? self.default_format.isbn : nil
  end
  
  def eisbn
    self.pdf_format ? self.pdf_format.isbn : nil
  end
  
  def self.to_dropdown
    all.sort_by(&:name_less_article).collect {|s| [s.name_for_dropdown, s.id]}
  end
  
  def name_for_dropdown
    "#{self.name}"
  end
  
  def sanitize_name
    # replace all none alphanumeric, underscore or periods with nothing
    # NB: regex \w chokes on unicode characters
    self.name.gsub(/[^0-9A-Za-z\-]/,'')
  end
  
  def author_inverted
    return unless self.author?
    if result = /(.*) (and|&) (.*)/.match(self.author)
      author = "#{Name.inverted(result[1])} and #{Name.inverted(result[3])}"
    else
      author = Name.inverted(self.author)
    end
  end
  
  def author_first
    if name = Name.parse(self.author)
      name[:first_name]
    else
      nil
    end
  end
  
  def author_last
    if name = Name.parse(self.author)
      name[:last_name]
    else
      nil
    end
  end
  
  def illustrator
    illustrator_contributor.try(:name)
  end
  
  def illustrator_inverted
    illustrator_contributor.try(:name_inverted)
  end
  
  def illustrator_contributor
    self.contributor_assignments.where("role like ?", "%Illustrator%").first.try(:contributor)
  end
  
  def reset_author_role
    set_contributor_role(self.author, "Author")
  end

  def set_contributor_role(contributor, role)
    ContributorAssignment.where("product_id = ? AND role = ?", self.id, role).each { |ca| ca.destroy }
    names = contributor.split(' and ')
    names.each do |name|
      c_data = {:name => name, :description => '', :default_role => role}
      contributor = Contributor.find_or_create_by_name(c_data)
      ca_data = {:product_id => self.id, :contributor_id => contributor.id, :role => role}
      ContributorAssignment.find_or_create_by_product_id_and_contributor_id_and_role(ca_data)
    end
  end

  def set_author_to_contributor
    role = "Author"
    if contributors = self.contributors.includes(:contributor_assignments).where("contributor_assignments.role = ?", role).order(:name)
      self.update_attribute(:author, contributors.map(&:name).to_sentence)
    end
  end

  def has_association?(assoc)
    assoc = assoc.to_s
    self.respond_to?(assoc) && !self.send(assoc).nil? && !self.send(assoc).is_a?(Array)
  end
  
  def association_value(assoc, method)
    self.send("has_association?", assoc.to_s) ? self.send(assoc.to_s).send(method.to_s) : nil
  end

  def duplicate
    omit_keys = %w(id proprietary_id catalog_page available_on updated_at created_at lccn lcclass copyright cip alsreadlevel alsinterestlevel alsquiznr alspoints lexile)
    new_product = self.class.new(self.attributes.delete_if {|k,v| omit_keys.include?(k)})
    new_product.bisac_subjects = self.bisac_subjects
    new_product.categories = self.categories
    new_product
  end
  
  def series
    if self.collection
      if self.collection.parent
        self.collection.parent
      else
        self.collection
      end
    else
      nil
    end
  end
  
  def subseries
    if self.collection
      if self.collection.parent
        self.collection
      else
        nil
      end
    else
      nil
    end
  end

  def features
    values = []
    values << "Table of contents" if self.has_table_of_contents
    values << "Informative sidebars" if self.has_sidebar
    values << "Timeline of key events" if self.has_timeline
    values << "Detailed maps" if self.has_map
    values << "Glossary of key words" if self.has_glossary
    values << "Sources for further research" if self.has_bibliography
    values << "Index" if self.has_index
    values << "Author/Illustrator biography" if self.has_author_biography
    values
  end
  
  def self.process_search_params(params)
    Rails.logger.debug("# DEBUG: params = #{params.inspect}")
    unless params[:q].blank?
      if /^978/.match(params[:q])
        params[:product_formats_isbn_in] = params[:q]
      else
        params[:name_contains] = params[:q]
        params[:product_formats_status_in] = ProductFormat::ACTIVE_STATUS_CODE
        params[:product_formats_format_id_equals] = Format::DEFAULT_ID if CONFIG[:default_format_only]
      end
    end
    # NB: dupe params since altering params affected sticky values in search form
    search_pairs = params.dup || {}
    # Remove unacceptable keys or blank values
    search_pairs.delete_if do |key,value|
      !SEARCHABLE_FIELDS.include?(key) || value.blank? || value == ['']
    end
    # Fix data
    search_pairs[:dewey_from] = sprintf("%03d", search_pairs[:dewey_from]) unless search_pairs[:dewey_from].blank?
    search_pairs[:dewey_to] = sprintf("%03d", search_pairs[:dewey_to]) unless search_pairs[:dewey_to].blank?
    search_pairs[:interest_level_max_id_from] = (search_pairs[:interest_level_from].to_i + 2) unless search_pairs[:interest_level_from].blank?
    search_pairs[:interest_level_min_id_to] = (search_pairs[:interest_level_to].to_i + 2) unless search_pairs[:interest_level_to].blank?
    search_pairs[:reading_level_id_from] = (search_pairs[:reading_level_from].to_i + 2) unless search_pairs[:reading_level_from].blank?
    search_pairs[:reading_level_id_to] = (search_pairs[:reading_level_to].to_i + 2) unless search_pairs[:reading_level_to].blank?
    search_pairs[:product_formats_isbn_in] = (search_pairs[:product_formats_isbn_in].gsub('-', '')) if search_pairs[:product_formats_isbn_in].is_a?(String)
    [:interest_level_from, :interest_level_to, :reading_level_from, :reading_level_to].each {|k| search_pairs.delete(k)}
    Rails.logger.debug("# DEBUG: search_pairs = #{search_pairs.inspect}")
    return search_pairs
  end

  def self.advanced_search(search_pairs, options = {})
    options[:order] ||= 'name'
    search = generate_search(search_pairs)
    count = search.count(:id, :distinct => true)
    if options[:per_page]
      search.order(options[:order]).paginate(:page => options[:page], :per_page => options[:per_page], :total_entries => count)
    else
      search.order(options[:order])
    end
  end

  def feedback
    fields = [self.isbn, self.name, self.collection.try(:name_extended), self.publisher, self.available_on]
    FEEDBACK.verbose(fields.join(', '))
  end

  protected

  def clean_name
    tmp = self.name
    # Remove stuff inside parentheses
    if result = /(.*) \(.*\)$/.match(tmp)
      logger.debug("Removing parentheses...")
      tmp = result[1]
    end
    # Remove series name
    if self.collection && result = /^#{Regexp.escape(self.collection.name)}: (.*)$/.match(tmp)
      logger.debug("Removing collection name...")
      tmp = result[1]
    end
    logger.debug("Clean name = #{tmp.inspect}")
    tmp
  end
  
  def calculate_title_and_subtitle
    logger.debug("Running product.calculate_title_and_subtitle method")
    logger.debug("  self = #{self.name} -- #{self.to_s} (#{self.id})")
    unless self.name_changed?
      logger.debug("Skip: Name did not change")
      return
    end
    if CONFIG[:calculate_title_and_subtitle] != true
      logger.debug("Skip: Config calculate_title_and_subtitle set to FALSE")
      return
    end
    tmp = clean_name
    if self.collection && /\?$/.match(self.collection.name) && result = /^#{Regexp.escape(self.collection.name)} (.*)$/.match(tmp)
      logger.debug("Using collection name as subtitle...")
      self.title = result[1]
      self.subtitle = self.collection.name
    elsif result = /(.*): (.*)$/.match(tmp)
      # Split on colon
      logger.debug("Splitting on colon...")
      self.title = result[1]
      self.subtitle = result[2]
    elsif result = /(.*\?) (.*)$/.match(tmp)
      # Split on question mark
      logger.debug("Splitting on question mark...")
      self.title = result[1]
      self.subtitle = result[2]
    else
      self.title = tmp
      self.subtitle = nil
    end
  end
  
  def self.generate_search(search_pairs)
    includes = []
    search = self.join_formats_with_distinct.available.order(:name)

    self_table = self.to_s.tableize
    exceptions = [self_table, 'product_formats']
    allowable_includes = exceptions + ['bisac_subjects']
    search_pairs.each_pair do |key, value|
      match = nil
      if table = allowable_includes.detect {|table| match = /^#{table}_(.+)/.match(key) }
        # Omit if table in exceptions -- they're already included
        includes << table unless exceptions.include?(table)
        key = "#{table}.#{match[1]}"
      else
        key = "#{self_table}.#{key}"
      end
      pattern = /(.+)_.+?$/
      # If the key ends with _from then we'll be looking for values greater than the param value
      if key.ends_with?("_from")
        key.gsub!(pattern, '\1')
        search = search.where("#{key} != '' AND #{key} IS NOT NULL AND #{key} >= ?", value)
      # If the key ends with _to then we'll be looking for values lesser than the param value
      elsif key.ends_with?("_to")
        key.gsub!(pattern, '\1')
        search = search.where("#{key} != '' AND #{key} IS NOT NULL AND #{key} <= ?", value)
      # If the key ends with _contains then we'll be looking for values LIKE the param value
      elsif key.ends_with?("_contains")
        key.gsub!(pattern, '\1')
        value = value.values.first if value.is_a?(Hash)
        search = search.where("#{key} LIKE ?", "%#{value}%")
      # If the key ends with _in then we'll be looking for values in an array
      elsif key.ends_with?("_in")
        key.gsub!(pattern, '\1')
        value = value.split(/,\s*/) if value.is_a?(String)
        value = value.values if value.is_a?(Hash)
        search = search.where("#{key} IN (?)", value)
      # If the key ends with _equals then we'll be looking for an exact match
      elsif key.ends_with?("_equals")
        key.gsub!(pattern, '\1')
        value = value.values.first if value.is_a?(Hash)
        search = search.where("#{key} = ?", value)
      # If none of the above then try to accommodate
      else
        value = value.values if value.is_a?(Hash)
        search = search.where(key => value)
      end
    end
    search = search.includes(includes) if includes.any?
    return search
  end

end

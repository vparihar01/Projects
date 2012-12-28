# Caveat: Assuming assemblies only contain like formatted items
# Eg, a pdf title can only be a part of a pdf assembly
# See product_exporter.rb for reason why
class Assembly < Product
  has_many :assembly_assignments, :dependent => :destroy
  has_many :titles, :through => :assembly_assignments, :order => :name
  belongs_to :collection

  def self.to_dropdown
    available.sort_by(&:name_less_article).collect {|s| [s.name_for_dropdown, s.id]}
  end
  
  # The first title, sorted alphabetically, is the sample for the Assembly
  def sample
    self.titles.available.where('excerpts.ipaper_id IS NOT NULL').order('name ASC').includes(:excerpt).first
  end
  
  # The first title in the assembly that has an ipaper
  def excerpt
    sample = self.sample
    sample.nil? ? nil : sample.excerpt
  end
  
  def downloads
    self.titles.available.collect(&:download)
  end
  
  # for a assembly, it returns the sum of alsquiz_count's of the titles
  def alsquiz_count
    self.titles.available.inject(0) {|sum, title| sum + title.alsquiz_count}
  end
  
  def name_for_dropdown
    "#{self.name}"
  end
  
  def subjects
    self.categories.map(&:name)
  end

  def is_price_equal_sum?
    results = {}
    self.product_formats.each do |assembly_format|
      results[assembly_format.to_s] = {}
      ProductFormat::PRICE_FIELDS.each do |price|
        results[assembly_format.to_s][price] = assembly_format.is_price_equal_sum?(price)
      end
    end
    results
  end

  def calculate_price
    logger.info("Running assembly.calculate_price method")
    logger.debug("  Self = #{self.name} (#{self.id})")
    if CONFIG[:calculate_assembly_price] == true
      logger.debug "Continue: Config calculate_assembly_price set to true"
      self.product_formats.each do |assembly_format|
        logger.info "  #{assembly_format.to_s}"
        prices = ProductFormat::PRICE_FIELDS.map{|x| assembly_format.send(x)}.join(" / ")
        logger.info "    Before: #{prices}"
        ProductFormat::PRICE_FIELDS.each do |price|
          # total is sum of respective product prices in assembly
          total = self.titles.map do |title|
            (pf = title.product_formats.find_by_format_id(assembly_format.format_id)) ? pf.send(price) : 0
          end.sum
          assembly_format.send("#{price}=", total)
        end
        assembly_format.save
        prices = ProductFormat::PRICE_FIELDS.map{|x| assembly_format.send(x)}.join(" / ")
        logger.info "    After:  #{prices}"
      end
    end
  end

  def self.no_collection
    all.map {|assembly| assembly unless Collection.find_by_name(assembly.name)}.compact
  end

  def self.fix_no_collection(assemblies)
    FEEDBACK.debug("fix_no_collection")
    assemblies.each do |assembly|
      FEEDBACK.print_record(assembly)
      Collection.create_from_assembly(assembly)
    end
  end

  def duplicate
    new_assembly = super
    new_assembly.titles = self.titles
    new_assembly
  end

  def assign_titles(new_titles)
    FEEDBACK.debug("assign_titles")
    current_title_ids = self.titles.map(&:id)
    touched = false
    new_titles.each do |title|
      if current_title_ids.include?(title.id)
        FEEDBACK.debug("  Skipping '#{title.name}' (#{title.id}) -- already assigned...")
      else
        FEEDBACK.debug("  Adding '#{title.name}' (#{title.id})...")
        self.titles << title
        touched = true
      end
    end
    if touched
      self.calculate_price
    end
  end

  def match_titles_status(options = {})
    FEEDBACK.debug("Assembly: #{self.name} (#{self.id})")
    self.product_formats.each do |apf|
      next if [ProductFormat::REPLACED_STATUS_CODE].include?(apf.status) && !options[:force]
      tpfs = ProductFormat.where("product_formats.product_id IN (?) AND product_formats.format_id = ?", self.titles.map(&:id), apf.format_id)
      statuses = tpfs.map(&:status).uniq.compact
      if statuses.size == 0
        FEEDBACK.verbose("  No title statuses found for #{apf} (#{apf.id})") if options[:verbose]
      elsif statuses.size == 1
        if apf.status == statuses[0]
          FEEDBACK.debug("#{apf} (#{apf.id}) status is correct: #{apf.status}")
        else
          FEEDBACK.verbose("  Fixing #{apf} (#{apf.id}) status: #{apf.status} -> #{statuses[0]}") if options[:verbose]
          apf.update_attribute(:status, statuses[0]) unless options[:debug] == true
        end
      else
        FEEDBACK.debug("Titles have mixed status: #{statuses.inspect}")
        # Remove active status
        non_active_statuses = statuses.reject {|v| v == ProductFormat::ACTIVE_STATUS_CODE}
        if non_active_statuses.size == 1
          if apf.status == non_active_statuses[0]
            FEEDBACK.debug("#{apf} (#{apf.id}) status is correct: #{apf.status}")
          else
            FEEDBACK.verbose("  Fixing #{apf} (#{apf.id}) status: #{apf.status} -> #{non_active_statuses[0]}") if options[:verbose]
            apf.update_attribute(:status, non_active_statuses[0]) unless options[:debug] == true
          end
        else
          # Just take the first option
          FEEDBACK.verbose("   Fixing #{apf} (#{apf.id}) status by using first non-active status: #{apf.status} -> #{non_active_statuses[0]}") if options[:verbose]
          apf.update_attribute(:status, non_active_statuses[0]) unless options[:debug] == true
        end
      end
    end
  end

  def set_date_to_first_available_title
    FEEDBACK.print_record(self)
    if title = self.titles.where("available_on is not null and available_on != ''").except(:order).order('available_on DESC').first
      FEEDBACK.debug "  Changing available_on from '#{self.available_on}' to '#{title.available_on}'..."
      self.update_attribute(:available_on, title.available_on)
    else
      FEEDBACK.debug "  Skip: Assembly has no titles with available_on set"
    end
  end

  def predecessor
    if self.available_on.blank?
      FEEDBACK.error("Cannot determine precedence because available_on is blank '#{self.name}' (#{self.id})")
      return nil
    end
    unless assembly = self.class.where("name = ? AND available_on IS NOT NULL AND available_on < ?", self.name, self.available_on).order('available_on DESC').first
      FEEDBACK.warning("Preceding assembly not found '#{self.name}' (#{self.id})")
      return nil
    end
    assembly
  end

  # When an assembly replaces another, need to copy titles from old assembly to new assembly
  def copy_titles_from_predecessor(options = {})
    return false unless predate = self.predecessor
    # update assembly assignments
    FEEDBACK.verbose "Source: '#{predate.name}' (#{predate.id})" if options[:verbose]
    FEEDBACK.verbose "Target: '#{self.name}' (#{self.id})" if options[:verbose]
    FEEDBACK.verbose "Copying assembly assignments (#{predate.id} => #{self.id})..." if options[:verbose]
    self.assign_titles(predate.titles) unless options[:debug]
  end

  # When an assembly replaces another, need to copy categories from old assembly to new assembly
  def copy_categories_from_predecessor(options = {})
    return false unless predate = self.predecessor
    # update assembly categories
    FEEDBACK.verbose "Source: '#{predate.name}' (#{predate.id})" if options[:verbose]
    FEEDBACK.verbose "Target: '#{self.name}' (#{self.id})" if options[:verbose]
    FEEDBACK.verbose "Copying assembly categories (#{predate.id} => #{self.id})..." if options[:verbose]
    predate.categories.each do |category|
      self.categories << category unless options[:debug] || self.categories.include?(category)
    end
  end

  def set_interest_level
    if title = self.titles.where('interest_level_min_id IS NOT NULL and interest_level_min_id != ""').order(:interest_level_min_id).first
      self.update_attribute(:interest_level_min_id, title.interest_level_min_id)
    end
    if title = self.titles.where('interest_level_max_id IS NOT NULL and interest_level_max_id != ""').order(:interest_level_max_id).last
      self.update_attribute(:interest_level_max_id, title.interest_level_max_id)
    end
  end
  
  def create_subassembly(isbns = {}, titles = [], status = ProductFormat::ACTIVE_STATUS_CODE, options = {})
    # NB: keys must be strings (NOT symbols) to match that returned by 'attributes' method
    options.stringify_keys!
    title = options['title'].blank? ? 'New Sub-Assembly (TBD)' : options['title']
    tmp = self.attributes.merge('name' => "#{self.name}: #{title}", 'title' => title)
    options = tmp.merge(options) # options take precedence over source assembly's attributes
    if subassembly = self.class.create(options)
      isbns.each do |format_id, isbn|
        subassembly.product_formats.create(:format_id => format_id, :isbn => isbn, :status => status)
      end
      subassembly.assign_titles(titles) if titles.any?
      subassembly.bisac_subjects << self.bisac_subjects
    else
      FEEDBACK.error("Failed to create sub-assembly '#{options.inspect}'")
    end
    subassembly
  end

  def create_composite(type = "covers", force = false)
    source1 = self.get_title_image(:type => type)
    source2 = self.get_title_image(:type => type, :exclude => source1)
    return false unless source1 && source2
    # create large with second title image
    size = :l
    target = Rails.root.join("public/images/#{type}/#{size.to_s}/#{self.isbn}.jpg")
    FEEDBACK.verbose "Creating '#{type}/#{size.to_s}'..."
    ImageConverter.convert(source2, target, force) do
      "#{CONFIG[:convert]} #{source1} #{ImageConverter::OPTIONS[size]} #{target}"
    end
    # create medium
    size = :m
    FEEDBACK.verbose "Creating '#{type}/#{size}'..."
    overlap = Rails.root.join("public/images/#{type}/#{size.to_s}/#{self.isbn}.jpg")
    ImageConverter.convert([source1, source2], overlap, force) do
      "#{CONFIG[:convert]} -size 1000x1000 xc:'#fff' \\( #{source1} -scale 15% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#ddd' -shadow 100x0+3+3 \\) +swap -background none -geometry +0+0 -layers merge \\) -composite \\( #{source2} -scale 15% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#ddd' -shadow 100x0+3+3 \\) +swap -background none -rotate #{CONFIG[:composite_image_rotation]} -geometry +20+35 -layers merge \\) -composite -trim -compress JPEG -quality 60% #{overlap}"
    end
    # create small
    size = :s
    FEEDBACK.verbose "Creating '#{type}/#{size}'..."
    overlap = Rails.root.join("public/images/#{type}/#{size.to_s}/#{self.isbn}.jpg")
    ImageConverter.convert([source1, source2], overlap, force) do
      "#{CONFIG[:convert]} -size 1000x1000 xc:'#fff' \\( #{source1} -scale 10% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#ddd' -shadow 100x0+2+2 \\) +swap -background none -geometry +0+0 -layers merge \\) -composite \\( #{source2} -scale 10% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#ddd' -shadow 100x0+2+2 \\) +swap -background none -geometry +30+30 -layers merge \\) -composite -trim -compress JPEG -quality 60% #{overlap}"
    end
  end
  
  def create_glider(force=false)
    source1 = self.get_title_image(:type => "covers")
    source2 = self.get_title_image(:type => "covers", :exclude => source1)
    return false unless source1 && source2
    target = Rails.root.join("public/images/gliders/#{self.isbn}.jpg")
    FEEDBACK.verbose "Creating glider..."
    ImageConverter.convert([source1, source2], target, force) do
      # "#{CONFIG[:convert]} -size 1000x1000 xc:transparent \\( #{source1} -scale 12% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#000' -shadow 30x0+3+3 \\) +swap -background none -geometry +0+0 -layers merge \\) -composite \\( #{source2} -scale 12% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#000' -shadow 30x0+3+3 \\) +swap -background none -rotate #{CONFIG[:glider_image_rotation]} -geometry +35+35 -layers merge \\) -composite -trim #{target}"  # PNG version
      "#{CONFIG[:convert]} -size 1000x1000 xc:'#7fa0bc' \\( #{source1} -scale 12% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#607B90' -shadow 100x0+3+3 \\) +swap -background none -geometry +0+0 -layers merge \\) -composite \\( #{source2} -scale 12% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#607B90' -shadow 100x0+3+3 \\) +swap -background none -rotate #{CONFIG[:glider_image_rotation]} -geometry +35+35 -layers merge \\) -composite -trim #{target}"
    end
  end
  
  def collect_images(type = "covers", options = {})
    dir_source = File.join(CONFIG[:image_archive_dir], type)
    dir_target = Rails.root.join("tmp/collect-assembly-#{type}/#{self.isbn}")
    FileUtils.rm_rf(dir_target, :noop => options[:debug], :verbose => options[:verbose])
    FileUtils.mkdir_p(dir_target, :noop => options[:debug], :verbose => options[:verbose])
    titles = self.titles.except(:order).order('available_on DESC')
    if options[:new] == true
      titles = titles.newly_available
    end
    if options[:limit].to_i > 0
      titles = titles.limit(options[:limit])
    end
    titles.each do |title|
      source = File.join(dir_source, "#{title.isbn}.jpg")
      target = File.join(dir_target, "#{title.isbn}.jpg")
      FileUtils.cp(source, target, :noop => options[:debug], :verbose => options[:verbose]) if File.exist?(source)
    end
    dir_target
  end

  protected

  def get_title_image(*args)
    options = args.extract_options!.symbolize_keys
    type = %w(covers spreads).include?(options[:type]) ? options[:type] : "covers"
    exclude = options[:exclude].is_a?(Array) ? options[:exclude] : Array(options[:exclude])
    if self.upcoming?
      self.titles.except(:order).order('available_on DESC')
    else
      self.titles.available.except(:order).order('available_on DESC')
    end
    if title = titles.detect {|t| source = File.join(CONFIG[:image_archive_dir], type, "#{t.isbn}.jpg") ; !exclude.include?(source) && File.exist?(source)}
      File.join(CONFIG[:image_archive_dir], type, "#{title.isbn}.jpg")
    else
      FEEDBACK.error "Cannot find '#{type.singularize}' image for Assembly '#{self.id}'"
      nil
    end
  end
  
end

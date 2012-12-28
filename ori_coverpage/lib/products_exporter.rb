module ProductsExporter
  TEMPLATES = {
    'standard' => {:file_format => 'csv'}, 
    'bakertaylor' => {:file_format => 'csv'}, 
    'blio' => {:file_format => 'csv'}, 
    'buyboard' => {:file_format => 'csv'}, 
    'buyboard_renewal' => {:file_format => 'csv'}, 
    'coresource_conversion' => {:file_format => 'csv'}, 
    'formats' => {:file_format => 'csv'}, 
    'edureference' => {:file_format => 'csv'}, 
    'follett' => {:file_format => 'csv'}, 
    'follettebook' => {:file_format => 'csv'}, 
    'follettedu' => {:file_format => 'csv'}, 
    'googledoc' => {:file_format => 'csv'}, 
    'gumdrop' => {:file_format => 'csv'}, 
    'ingram' => {:file_format => 'csv'}, 
    'guidedlevels' => {:file_format => 'csv'}, 
    'isbns' => {:file_format => 'csv'}, 
    'k12buy' => {:file_format => 'csv'}, 
    'mba' => {:file_format => 'csv'}, 
    'nyc' => {:file_format => 'csv'}, 
    'onix' => {:file_format => 'xml'}, 
    'orderform' => {:file_format => 'csv'}, 
    'price_change' => {:file_format => 'csv'}, 
    'replist' => {:file_format => 'csv'}, 
    'sebco' => {:file_format => 'csv'}, 
    'sebcoebook' => {:file_format => 'csv'}, 
  }

  def self.all(options = {})
    file_paths = {}
    TEMPLATES.each do |k, v|
      file_paths[k] = execute(k, options)
    end
    file_paths
  end

  def self.execute(products, options = {})
    template = options[:data_template]
    (FEEDBACK.error("Undefined 'data_template'") and return false) unless TEMPLATES.has_key?(template)
    basename = options.delete(:basename) do |x|
      default_basename(:include_template => template, :include_date => true)
    end
    file_format = TEMPLATES[template][:file_format]
    if options[:data_format_ids].blank?
      options[:data_format_ids] = Format.find_single_units.map(&:id)
    end
    file_path = get_file_path(basename, file_format)

    # Assuming force option is not set. Default to true.
    unless File.exist?(file_path) && options[:force] == false
      product_formats = ProductFormat.includes(:product).where(:product_id => products).where(:format_id => options[:data_format_ids])
      product_formats = product_formats.where(:status => options[:status]) unless options[:status].blank?
      self.send(file_format, product_formats.order('products.name'), file_path, options)
    else
      FEEDBACK.verbose "Skip export: Using pre-existing file '#{file_path}'"
    end

    file_path
  end

  def self.execute_as_grouped(product_formats, options = {})
    template = options[:data_template]
    (FEEDBACK.error("Undefined 'data_template'") and return false) unless TEMPLATES.has_key?(template)
    file_format = TEMPLATES[template][:file_format]
    (FEEDBACK.error("Template must be 'csv' file format") and return false) unless file_format == 'csv'
    basename = options.delete(:basename) do |x|
      default_basename(:include_template => template, :include_date => true)
    end
    if options[:data_format_ids].blank?
      format_id = Format::DEFAULT_ID
    elsif options[:data_format_ids].is_a?(Array)
      FEEDBACK.warning("Can only export one format at a time. Choosing first.")
      format_id = options[:data_format_ids].first
    else
      format_id = options[:data_format_ids]
    end
    file_path = get_file_path(basename, file_format)

    price_date = (options[:use_price_change] ? Product.upcoming_on : nil)
    FasterCSV.open(file_path, "w", {:row_sep => "\n", :force_quotes => true}) do |csv|
      csv << self.send("#{template}_header")
      product_formats.each do |pf|
        p = pf.product
        if tmp = self.send("#{template}_row", p, pf, price_date)
          csv << tmp
        end
        if p.respond_to?(:titles)
          p.titles.includes(:product_formats).where('product_formats.format_id' => format_id).each do |t|
            tpf = t.product_formats.where('product_formats.format_id' => format_id).first
            if tmp = self.send("#{template}_row", t, tpf, price_date)
              csv << tmp
            end
          end
        end
      end
    end

    file_path
  end

  def self.default_basename(options = {:include_template => false, :include_date => false})
    include_template = options.delete(:include_template)
    include_date = options.delete(:include_date)
    t = (include_template.is_a?(String) ? include_template : (include_template == true ? template : nil))
    d = (include_date ? (include_date.is_a?(Date) ? include_date.strftime("%Y%m%d") : (include_date == true ? Date.today.strftime("%Y%m%d") : nil)) : nil)
    [CONFIG[:export_basename], t, d].compact.join('-')
  end
  
  def self.get_file_path(basename, file_format)
    Rails.root.join("tmp", "#{basename}.#{file_format}")
  end
  
  protected
  
  def self.csv(product_formats, file_path, options = {})
    template = options[:data_template]
    FasterCSV.open(file_path, "w", {:row_sep => "\n", :force_quotes => true}) do |csv|
      csv << self.send("#{template}_header")
      product_formats.each do |pf|
        if tmp = self.send("#{template}_row", pf.product, pf)
          csv << tmp
        end
      end
    end
    return file_path
  end

  def self.isbns_header
    ["id", "isbn", "hardcover isbn", "pdf isbn", "paperback isbn", "name", "title", "subtitle", "type", "language", "audience", "reading level", "interest level begin", "interest level end", "product form", "product detail", "number of pages", "publication date", "status code", "copyright year", "list price", "s/l price", "publisher", "imprint", "series title", "series id", "dimensions (width x height)", "weight", "dewey", "graphics", "description", "word count", "lexile", "atos quiz number", "atos points", "atos reading level", "atos interest level", "guided reading level", "bisac subject code 1", "bisac subject code 2", "bisac subject code 3", "subject 1", "subject 2", "subject 3", "contributor 1", "role 1", "contributor 2", "role 2", "contributor 3", "role 3", "contributor 4", "role 4", "contributor 5", "role 5"]
  end
  
  def self.isbns_row(p, pf)
    type = ()
    row = [pf.id, pf.isbn, p.association_value(:default_format, :isbn13str), p.association_value(:pdf_format, :isbn13str), p.association_value(:trade_format, :isbn13str), p.name, p.title, p.subtitle, Product::TYPES[p.class.to_s], p.language, translate(p, :audience, :value), p.association_value(:reading_level, :abbreviation), p.association_value(:interest_level_min, :abbreviation), p.association_value(:interest_level_max, :abbreviation), pf.format.form, pf.format.detail, p.pages, p.available_on.try(:to_s, :us), translate(pf, :status, :value), p.copyright, pf.price_list, pf.price, p.publisher, p.imprint, p.association_value(:collection, :name_extended), p.collection_id, pf.dimensions, (pf.weight.nil? || pf.weight == 0 ? "" : pf.weight), p.dewey, p.graphics, p.description, p.word_count, p.lexile, p.alsquiznr, p.alspoints, p.alsreadlevel, p.alsinterestlevel, p.guided_level]
    row += get_bisacs(p, 3)
    row += get_subjects(p, 3)
    row += get_contributors(p, 5)
    row
  end
  
  def self.standard_header
    ["id", "isbn", "isbn-10", "name", "title", "subtitle", "type", "language", "audience", "reading level", "interest level begin", "interest level end", "product form", "product detail", "number of pages", "publication date", "status code", "copyright year", "list price", "s/l price", "publisher", "imprint", "series title", "series id", "subseries title", "subseries id", "dimensions (width x height)", "weight", "dewey", "graphics", "description", "word count", "lexile", "atos quiz number", "atos points", "atos reading level", "atos interest level", "guided reading level", "bisac subject code 1", "bisac subject code 2", "bisac subject code 3", "subject 1", "subject 2", "subject 3", "contributor 1", "role 1", "contributor 2", "role 2", "contributor 3", "role 3", "contributor 4", "role 4", "contributor 5", "role 5"]
  end
  class << self
    alias_method :xls_header, :standard_header
  end
  
  def self.standard_row(p, pf, date = nil)
    type = ()
    row = [pf.id, pf.isbn13str, pf.isbn10str, p.name, p.title, p.subtitle, Product::TYPES[p.class.to_s], p.language, translate(p, :audience, :value), p.association_value(:reading_level, :abbreviation), p.association_value(:interest_level_min, :abbreviation), p.association_value(:interest_level_max, :abbreviation), pf.format.form, pf.format.detail, p.pages, p.available_on.try(:to_s, :us), translate(pf, :status, :value), p.copyright, pf.price_list_on(date), pf.price_on(date), p.publisher, p.imprint, p.series.try(:name), p.series.try(:id), p.subseries.try(:name), p.subseries.try(:id), pf.dimensions, (pf.weight.nil? || pf.weight == 0 ? "" : pf.weight), p.dewey, p.graphics, p.description, p.word_count, p.lexile, p.alsquiznr, p.alspoints, p.alsreadlevel, p.alsinterestlevel, p.guided_level]
    row += get_bisacs(p, 3)
    row += get_subjects(p, 3)
    row += get_contributors(p, 5)
    row
  end
  class << self
    alias_method :xls_row, :standard_row
  end
  
  def self.bakertaylor_header
    ["isbn", "title", "subtitle", "language", "bisac subject code 1", "bisac subject code 2", "bisac subject code 3", "grade level begin", "grade level end", "subject development", "physical format", "physical format2", "cpsia warning", "author 1", "role 1", "author 2", "role 2", "author 3", "role 3", "author 4", "role 4", "author 5", "role 5", "number of pages", "runtime", "publication date", "report code", "on sale date", "copyright year", "list price", "net price", "vendor name", "imprint name", "acceptable discount", "series title", "series no", "volume number", "number of volumes", "edition number", "edition", "part number", "print run", "advertising budget", "vendor product id", "replacement isbn", "previous isbn", "carton quantity", "depth (thickness)", "height (length)", "width", "weight"]
  end
  
  def self.bakertaylor_row(p, pf)
    cpsia = 7 # No choking hazard warning necessary (not applicable to a product)
    row = [pf.isbn13str, p.title, p.subtitle, p.language]
    row += get_bisacs(p, 3)
    row += [translate(p, :interest_level_min_id, :bakertaylor), translate(p, :interest_level_max_id, :bakertaylor)]
    row += get_subjects(p, 1)
    row += [translate(pf.format, :form, :bakertaylor), translate(pf.format, :detail, :bakertaylor), cpsia]
    row += get_contributors(p, 5)
    row += [p.pages, nil, p.available_on.try(:to_s, :us), translate(pf, :status, :bakertaylor), p.available_on.try(:to_s, :us), p.copyright, pf.price_list, nil, p.publisher, (p.imprint.blank? ? p.publisher : p.imprint), nil, p.association_value(:collection, :name_extended), nil, nil, nil, nil, nil, nil, nil, nil, pf.id, nil, nil, nil, nil, pf.height, pf.width]
    row << (pf.weight.nil? || pf.weight == 0 ? "" : pf.weight)
    row
  end
  
  def self.blio_header
    ["eISBN", "Title", "Author"]
  end
  
  def self.blio_row(p, pf)
    row = [pf.isbn, p.name, p.author]
  end

  def self.buyboard_header
    ["Publisher", "Description", "ISBN 10", "ISBN 13", "Related ISBN", "Author", "Language", "Material Type", "MLC", "Subject", "Grade Level", "Grade", "Unit Price", "Unit Measure", "Full Description", "Copyright Year", "Media Format", "Edition", "New Resell", "Student Teacher Ratio", "Proclamation Year", "State Adopted", "Commissioners List", "TEKS", "TEKS URL", "State Standards", "State Standards URL", "Common Core", "Common Core URL", "National Standards", "National Standards URL", "Product URL", "Sample URL", "Marketing URL", "Volume Discounts ", "Staff Development Costs", "Subscription Costs", "Implementation Costs", "Maintenance Costs", "Replacement Costs", "Shipping Costs", "Other Associated Costs"]
  end

  def self.buyboard_row(p, pf, date = nil)
    row = [p.publisher, p.name, pf.isbn10, pf.isbn13]
    # TODO: Related ISBN -- ISBNs of all products related to the primary product (e.g., teacher edition)
    row << nil
    row += [p.author, p.language]
    # TODO: Material type -- Select from: Student Edition; Teacher Edition; Student Resource; Teacher Resource; Ancillary
    row << "Student Resource"
    # TODO: Multiple List Code -- 4-digit Texas code if known; otherwise, leave blank
    row << nil
    # Subject -- If MLC is left blank, select from: English, Mathematics, Science, Social Studies, LOTE, Fine Arts, Other
    #row << ["English", "Mathematics", "Science", "Social Studies", "LOTE", "Fine Arts"].detect {|x| p.subjects.map{|y| translate_value(y, APP_SUBJECTS, :buyboard)}.include?(x)}
    row << p.subjects.map{|y| translate_value(y, APP_SUBJECTS, :buyboard)}.uniq.join(", ")
    # Grade Level -- Select from: Elementary, Middle School, or High School
    row << translate(p, :audience, :buyboard)
    # Grade Level could be more specific using reading level:
    # row << case p.reading_level.try(:id)
    # when 11..14
    #   "High School"
    # when 9..10
    #   "Middle School"
    # when 1..8
    #   "Elementary"
    # else
    #   nil
    # end
    row += [p.reading_level.try(:abbreviation), pf.price_on(date)]
    # TODO: Unit of Measure -- Select from: per student, per teacher, per system, per district
    row << "per system"
    row += [p.description, p.copyright]
    # Media Format -- Select from: None; Print with Video/DVD; Primarily Print; Print with Online Access; Electronic -Non-Interactive Online; Electronic -Non-Interactive - CD-ROM; Electronic -Non-Interactive-Video/DVD; Electronic -Interactive Video;  Electronic-Interactive Online
    row << translate(pf.format, :detail, :buyboard)
    row << nil
    # TODO: Edition/revision
    row << nil
    row << "New"
    12.times { |i| row << nil }
    rel = "images/covers/m/#{p.isbn}.jpg"
    cover_url = File.exist?(Rails.root.join("public", rel)) ? File.join(CONFIG[:app_url], rel) : nil
    sample_url = product_url = File.join(CONFIG[:app_url], "shop/show/#{p.id}")
    row += [cover_url, sample_url, product_url]
    6.times { |i| row << "None" }
    # TODO: Shipping costs
    row << nil
    row << "None"
    row
  end

  def self.buyboard_renewal_header
    ["Part Number", "Manufacturer Name", "Category", "Short Description", "Full Description", "Unit of Measure", "Pack_Qty", "Pack_Weight", "Price", "Item URL"]
  end

  def self.buyboard_renewal_row(p, pf, date = nil)
    row = [pf.isbn, p.name]
    # Category: Using recommended subjects
    #row += get_subjects(p, 1)
    row << p.subjects.map{|y| translate_value(y, APP_SUBJECTS, :buyboard)}.uniq.join(", ")
    row += [p.description, p.description, "EA", pf.title_count, nil, pf.price_on(date)]
    row << File.join(CONFIG[:app_url], "shop/show/#{p.id}")
  end

  def self.coresource_conversion_header
    ["Date of Conversion Request", "RUSH REQUIRED (YES/NO) Date if yes", "Parent ISBN", "eISBN", "Publisher", "Title", "Source File", "Conversion Request Type", "Special Comments Requirements"]
  end
  
  def self.coresource_conversion_row(p, pf)
    row = [Date.today.to_s(:us), nil, p.association_value(:default_format, :isbn13), p.association_value(:pdf_format, :isbn13), p.publisher, p.name, "#{p.association_value(:pdf_format, :isbn13)}_WEB.pdf", "ePub", nil]
  end
  
  def self.formats_header
    ["id", "hardcover isbn", "isbn", "name", "title", "subtitle", "type", "language", "audience", "reading level", "interest level begin", "interest level end", "product form", "product detail", "number of pages", "publication date", "status code", "copyright year", "list price", "s/l price", "publisher", "imprint", "series title", "series id", "dimensions (width x height)", "weight", "dewey", "graphics", "description", "word count", "lexile", "atos quiz number", "atos points", "atos reading level", "atos interest level", "guided reading level", "bisac subject code 1", "bisac subject code 2", "bisac subject code 3", "subject 1", "subject 2", "subject 3", "contributor 1", "role 1", "contributor 2", "role 2", "contributor 3", "role 3", "contributor 4", "role 4", "contributor 5", "role 5"]
  end
  
  def self.formats_row(p, pf)
    row = [pf.id, p.association_value(:default_format, :isbn13str), pf.isbn13str, p.name, p.title, p.subtitle, Product::TYPES[p.class.to_s], p.language, translate(p, :audience, :value), p.association_value(:reading_level, :abbreviation), p.association_value(:interest_level_min, :abbreviation), p.association_value(:interest_level_max, :abbreviation), pf.format.form, pf.format.detail, p.pages, p.available_on.try(:to_s, :us), translate(pf, :status, :value), p.copyright, pf.price_list, pf.price, p.publisher, p.imprint, p.association_value(:collection, :name_extended), p.collection_id, pf.dimensions, (pf.weight.nil? || pf.weight == 0 ? "" : pf.weight), p.dewey, p.graphics, p.description, p.word_count, p.lexile, p.alsquiznr, p.alspoints, p.alsreadlevel, p.alsinterestlevel, p.guided_level]
    row += get_bisacs(p, 3)
    row += get_subjects(p, 3)
    row += get_contributors(p, 5)
    row
  end
  
  def self.edureference_header
    ["ProdType", "ISBN", "SeriesName", "SubseriesName", "ProdName", "AuthorFirstLast", "IllustratorFirstLast", "Copyright", "DateAvailable", "PriceList", "PriceLibrary", "ReadLevel", "InterestLevel", "TrimSize", "Pages", "Graphics", "Binding", "Dewey", "ARPoints", "ARReadLevel", "BISAC", "CatalogPage", "Subject", "Annotation", "Status"]
  end

  
  def self.edureference_row(p, pf, date = nil)
    row = [Product::TYPES[p.class.to_s], pf.isbn13str, p.series.try(:name), p.subseries.try(:name), p.name, p.author, p.illustrator, p.copyright, p.available_on, pf.price_on(date), pf.price_list_on(date), p.association_value(:reading_level, :name), p.interest_level_range, pf.dimensions, p.pages, p.graphics, pf.format.detail, p.dewey, p.alspoints, p.alsreadlevel]
    row += get_bisacs(p, 1)
    row += [p.catalog_page]
    row += get_subjects(p, 1)
    row += [p.description, translate(pf, :status, :value)]
    row
  end
  
  def self.follett_header
    ["B = Book", "Catalog Page #", "Page Count", "Title", "Author Last, First", "Author Last, First", "Imprint", "ISBN", "Dewey", "Purch Pub", "Date Available", "Order by Date", "Public Release", "Publisher", "School Interest Level", "Age Low", "Age High", "Grade Low", "Grade High", "Disc Code", "Stock Type", "FLR ISBN", "Copy Yr", "List Price", "Cost", "Binding", "Market Flag", "Bindery", "Binding Cost", "Init QT", "UPC/EAN", "Vendor ID", "Language", "Temp", "Threshold", "Temp Date", "Length", "Temp Notes", "Series", "Format 1", "Format 2", "Video Rating", "Physical Desc", "BWI #", "F&P Level", "DRA Level", "Guided Reading Level", "Annotation", "BISAC CODE"]
  end
  
  def self.follett_row(p, pf)
    row = [nil, p.catalog_page, p.pages, p.name, p.author_inverted, nil, p.imprint, pf.isbn13str, p.dewey, nil, p.available_on.try(:to_s, :us), nil, p.available_on.try(:to_s, :us), p.publisher, "#{p.association_value(:interest_level_min, :abbreviation)}#{p.association_value(:interest_level_max, :abbreviation)}", nil, nil, nil, nil, nil, nil, nil, p.copyright, pf.price, nil, translate(pf.format, :detail, :value), nil, nil, nil, nil, nil, nil, p.language, nil, nil, nil, nil, nil, p.association_value(:collection, :name_extended), nil, nil, nil, nil, nil, nil, nil, p.guided_level, p.description]
    row += get_bisacs(p, 1)
    row
  end
  
  def self.follettebook_header
    ["Title", "Author", "Date-Available", "LibraryBinding-Isbn", "E-Isbn", "List-Price"]
  end
  
  def self.follettebook_row(p, pf)
    row = [p.name, p.author, p.available_on, p.default_format.isbn, p.pdf_format.isbn, p.pdf_format.price]
  end
  
  def self.follettedu_header
    ["ProdType", "ISBN", "SeriesName", "SubseriesName", "ProdName", "AuthorFirstLast", "IllustratorFirstLast", "Copyright", "DateAvailable", "PriceList", "PriceLibrary", "ReadLevel", "InterestLevel", "TrimSize", "Pages", "Graphics", "Binding", "Dewey", "ARPoints", "ARReadLevel", "BISAC", "Subject", "Annotation"]
  end
  
  def self.follettedu_row(p, pf)
    row = [Product::TYPES[p.class.to_s], pf.isbn13str, p.series.try(:name), p.subseries.try(:name), p.name, p.author, p.illustrator, p.copyright, p.available_on.try(:to_s, :us), pf.price_list, pf.price, p.association_value(:reading_level, :name), p.interest_level_range, pf.dimensions, p.pages, p.graphics, pf.format.detail, p.dewey, p.alspoints, p.alsreadlevel]
    row += get_bisacs(p, 1)
    row += get_subjects(p, 1)
    row += [p.description]
    row
  end
  
  def self.googledoc_header
    # these column headers must correspond to actual product or product_format table column names
    %w(name type series subseries set1 set2 set3 description author price price_list isbn pdf_isbn trade_isbn hosted_isbn reading_level interest_level_min interest_level_max dimensions pages copyright available_on dewey graphics binding_type spotlight_description alsquiznr alspoints alsreadlevel alsinterestlevel guided_level subject1 subject2 illustrator publisher imprint bisacs annotation language audience catalog_page proprietary_id has_index has_bibliography has_glossary has_sidebar has_table_of_contents has_author_biography has_map has_timeline packager)
  end
  
  def self.googledoc_row(p, pf)
    row = [p.name, Product::TYPES[p.class.to_s], p.series.try(:name), p.subseries.try(:name), nil, nil, nil, p.description, p.author, p.association_value(:default_format, :price), p.association_value(:default_format, :price_list), p.association_value(:default_format, :isbn), p.association_value(:pdf_format, :isbn), p.association_value(:trade_format, :isbn), nil, p.association_value(:reading_level, :abbreviation), p.association_value(:interest_level_min, :abbreviation), p.association_value(:interest_level_max, :abbreviation), p.association_value(:default_format, :dimensions), p.pages, p.copyright, p.available_on.try(:to_s, :us), p.dewey, p.graphics, "Library binding", p.spotlight_description, p.alsquiznr, p.alspoints, p.alsreadlevel, p.alsinterestlevel, p.guided_level]
    row += get_subjects(p, 2)
    row += [p.illustrator, p.publisher, p.imprint, p.bisac_subjects.map(&:code).join(', '), p.annotation, p.language, p.audience, p.catalog_page, p.proprietary_id, p.has_index, p.has_bibliography, p.has_glossary, p.has_sidebar, p.has_table_of_contents, p.has_author_biography, p.has_map, p.has_timeline, p.packager]
  end
  
  def self.gumdrop_header
    ["ISBN", "SkuNo", "Title", "Author First Name", "Author Last Name", "Pages", "Publisher", "Vendor", "Copyright", "Language", "Grade Levels", "Dewey", "Date Available", "SetNo", "Series Name", "New Series", "Existing Series", "Series Description", "TRIM=W X L", "Have Sample or Need F&G", "CAN/NCAN", "Desc. Status", "Image Status", "New Publisher", "Existing Publisher", "Sample Price", "Pub. List Price", "CAN Pub. List Price", "Individual GD Price", "CAN GD Price", "S&L price", "CAN S&L price", "Binding", "Chapter Book", "Picture Book", "Graphic Novel", "Fiction", "Non Fiction", "AR Test #", "USA  Series GD Pricing", "USA Series List Price", "CAN Series GD Pricing", "CAN Series List Price", "COGS"]
  end
  
  def self.gumdrop_row(p, pf)
    new_series = old_series = nil
    if p.respond_to?(:collection)
      new_series = (p.collection.new? ? 'Yes' : 'No')
      old_series = (p.collection.new? ? 'No' : 'Yes')
    end
    row = [pf.isbn13str, nil, p.name, p.author_first, p.author_last, p.pages, p.publisher, nil, p.copyright, p.language, p.interest_level_range, p.dewey, p.available_on, p.collection_id, p.association_value(:collection, :name_extended), new_series, old_series, p.association_value(:collection, :description), pf.dimensions, nil, nil, nil, nil, nil, 'Yes', nil, pf.price_list, nil, nil, nil, pf.price, nil, pf.format.detail, 'Yes', nil, nil, nil, 'Yes', p.alsquiznr, nil, nil, nil, nil, nil]
  end
  
  def self.ingram_header
    ["ISBN", "EAN", "UPC", "Title", "Sub Title", "Edition", "Edition Desc", "Series Name", "Series Num", "Cont 1", "Cont 1 Role", "Cont 2", "Cont 2 Role", "Cont 3", "Cont 3 Role", "Imprint", "Pubdate", "Status", "Media", "Binding", "List Price", "CAD Price", "Disc Perc", "Ctn Qty", "Pages", "BISAC Subject", "Audience", "Language", "Product Description"]
  end
  
  def self.ingram_row(p, pf)
    row = [pf.isbn10str, pf.isbn13str, nil, p.title, p.subtitle, nil, nil, p.association_value(:collection, :name_extended), nil]
    row += get_contributors(p, 3)
    row += [(p.imprint.blank? ? p.publisher : p.imprint), (p.available_on ? p.available_on.strftime("%m%Y") : ""), translate(pf, :status, :ingram), translate(pf.format, :form, :ingram), translate(pf.format, :detail, :ingram), pf.price_list, nil, nil, nil, p.pages, get_bisacs(p, 1), translate(p, :audience, :ingram), translate(p, :language, :ingram), p.description]
    row
  end
  
  def self.guidedlevels_header
    ["EAN", "GRL"]
  end
  
  def self.guidedlevels_row(p, pf)
    row = [pf.isbn, p.guided_level]
  end
  
  def self.k12buy_header
    ["Vendor Name", "Vendor TaxID", "Publisher", "Parent Company", "ISBN", "Title", "List Price", "Unit Price", "Currency", "Item Description", "Unit of Measure", "Product Classification Code", "Recipient", "Tax Applies", "VAT or GST Applies", "Shipping Charges Apply", "Defined Shipping Amount", "Defined Shipping Amount as Percentage", "Vendor ItemID", "Edition", "Available for Retail Sale", "Available for Retail Sale Price", "Consumable", "Assessment", "Family Title", "Class Title", "Shipping Dimensions", "Shipping Weight", "Unit of Measure for Shipping Weight", "Binding", "Fullsize Picture Filename 1", "Grade Pre-K", "Grade K", "Grade 1", "Grade 2", "Grade 3", "Grade 4", "Grade 5", "Grade 6", "Grade 7", "Grade 8", "Grade 9", "Grade 10", "Grade 11", "Grade 12", "Higher Learning", "Condition Used", "Used Condition Status", "Drop Shipped Flag", "Min Order Qty", "Max Order Qty", "Customer Number", "Included Items", "Associated Items", "Suitable Replacement Items", "Vendor Product Item UPC Number", "Tier I Quantity", "Tier I Price", "Tier II Quantity", "Tier II Price", "Tier III Quantity", "Tier III Price", "Tier IV Quantity", "Tier IV Price", "Tier V Quantity", "Tier V Price", "Gratis Tier I Quantity", "Gratis Tier I Item Number", "Gratis Tier II Quantity", "Gratis Tier II Item Number", "Non-Calculated Gratis", "Non-Calculated Gratis Contact Information", "Non-Calculated Gratis Expiration Date", "Additional Information Bullet URL", "Additional Information Bullet 1", "Additional Information Bullet 2", "Additional Information Bullet 3", "Additional Information Bullet 4", "Additional Information Bullet 5", "Additional Information Bullet 6", "Additional Information Bullet 7", "Additional Information Bullet 8", "Additional Information Bullet 9", "Additional Information Bullet 10", "Fullsize Picture Filename 2", "Fullsize Picture Filename 3", "Fullsize Picture Filename 4", "Fullsize Picture Filename 5", "Author", "Language", "Option1 Vendor ItemID", "Option1 Description", "Option1 Price", "Option2 Vendor ItemID", "Option2 Description", "Option2 Price", "Option3 Vendor ItemID", "Option3 Description", "Option3 Price", "Option4 Vendor ItemID", "Option4 Description", "Option4 Price", "Option5 Vendor ItemID", "Option5 Description", "Option5 Price", "PO Grouping"]
  end
  
  def self.k12buy_row(p, pf)
    row = [CONFIG[:company_name], CONFIG[:tax_id], CONFIG[:company_name], CONFIG[:company_name], pf.isbn13, p.title, pf.price_list]
    # 35% discount for paperback, standard discount otherwise
    row << (pf.format_id == Format::TRADE_ID ? (pf.price_list * 0.65).round(2) : pf.price)
    row += ['USD', p.description]
    row << (p.respond_to?(:titles) ? 'SET' : 'EA')
    row += ['55000000', 'STUDENT', 'NO', 'NO']
    # Cherrylake: free shipping only in this case
    # row << (CONFIG[:free_shipping_for_institutions] == true ? 'None' : 'Defined%')
    row << 'None'
    row << nil
    # Cherrylake: free shipping only in this case
    # row << (CONFIG[:free_shipping_for_institutions] == true ? nil : "#{CONFIG[:shipping_cost_factor].to_f * 100}%")
    row << nil
    row += [pf.id, p.copyright, 'YES', pf.price_list, nil, nil, 'Books', 'Student', pf.dimensions]
    row += [(pf.weight.nil? || pf.weight == 0 ? "" : "#{pf.weight / 16}"), "Lbs"]
    row << pf.format.form
    rel = "images/covers/l/#{p.isbn}.jpg"
    cover_url = File.exist?(Rails.root.join("public", rel)) ? File.join(CONFIG[:app_url], rel) : nil
    # rel = "images/covers/m/#{p.isbn}.jpg"
    # thumbnail_url = File.exist?(Rails.root.join("public", rel)) ? File.join(CONFIG[:app_url], rel) : nil
    # product_url = File.join(CONFIG[:app_url], "shop/show/#{p.id}")
    row << cover_url
    if p.interest_level_min && p.interest_level_max
      # Pre = -1, K = 0, Higher learning = 13
      (-1..13).each do |k|
        row << (k >= p.interest_level_min.try(:value) && k <= p.interest_level_max.try(:value) ? 'YES' : nil)
      end
    else
      15.times { |i| row << nil }
    end
    6.times { |i| row << nil }
    if p.respond_to?(:titles)
      isbns = p.titles.map {|t| t.product_formats.where(:format_id => pf.format_id).first.try(:isbn)}
      row << isbns.compact.join(', ')
    else
      row << nil
    end
    row << nil
    if r = p.replacement
      row << r.product_formats.where(:format_id => pf.format_id).first.try(:isbn)
    else
      row << nil
    end
    18.times { |i| row << nil }
    row << File.join(CONFIG[:app_url], "shop/show/#{p.id}")
    row += [pf.format.detail, (p.pages.blank? ? nil : "#{p.pages} pages"), (p.copyright.blank? ? nil : "Copyright #{p.copyright}"), "Date Available: #{p.available_on}", (p.dewey.blank? ? nil : "Dewey: #{p.dewey}"), "BISAC: #{p.bisac_subjects.map(&:code).join(', ')}", (p.lexile.blank? ? nil : "Lexile: #{p.lexile}")]
    if collection = p.series
      row << "Series: #{collection.name}"
    else
      row << nil
    end
    if collection = p.subseries
      row << "Subseries: #{collection.name}"
    else
      row << nil
    end
    7.times { |i| row << nil }
    row += [p.author, p.language]
    row
  end
  
  def self.mba_header
    ["Job ID", "Series Name", "Title", "Subtitle", "Author(s)", "Lib. Bdg. Series ISBN (13)", "Lib. Bdg. ISBN (13) ", "School Lib. Bdg. Price", "Pbk. Series ISBN (13)", "Pbk. ISBN (13)", "School Pbk. Price", "PDF Series ISBN (13)", "Pdf ISBN (13)", "School Pdf Price", "Hosted Series ISBN (13)", "Hosted ISBN (13)", "School Hosted Price", "Pages", "Trim", "Bib Pg", "Index ", "Glossary", "Photos/Illus", "Maps", "Charts", "Reading Level Grade", "Interest Level Grade", "Dewey Number", "Brief Summary for each title", "AR", "AR Grade", "AR Reading Level", "AR Points", "AR Quiz #", "Reading Counts", "RC Interest Level", "RC Reading Level", "RC Points", "RC Quiz#", "Lexile", "Guided Reading Level", "Copyright", "Date Available", "Hosted URL"]
  end
  
  def self.mba_row(p, pf, date = nil)
    if p.is_a?(Assembly)
      row = [nil, nil, "#{p.title} (#{p.titles.count})", p.subtitle, nil]
      # Iterate over format ids (library, trade, pdf, hosted)
      [1, 2, 3, 4].each do |i|
        if temp_format = p.product_formats.where(:format_id => i).first
          row += [temp_format.isbn13str, nil, temp_format.price_on(date)]
        else
          3.times { |i| row << nil }
        end
      end
      26.times { |i| row << nil }
    else
      row = [nil, p.association_value(:collection, :name_extended), p.title, p.subtitle, p.author]
      # Iterate over format ids (library, trade, pdf, hosted)
      [1, 2, 3, 4].each do |i|
        if temp_format = p.product_formats.where(:format_id => i).first
          row += [nil, temp_format.isbn13str, temp_format.price_on(date)]
        else
          3.times { |i| row << nil }
        end
      end
      row += [p.pages, p.association_value(:default_format, :dimensions), (p.has_bibliography ? "Y" : "N"), (p.has_index ? "Y" : "N"), (p.has_glossary ? "Y" : "N"), p.graphics, (p.has_map ? "Y" : "N"), nil, p.association_value(:reading_level, :abbreviation), p.interest_level_range, p.dewey, p.description]
      # Accelerated data
      if p.alsquiznr == "Pending" || p.available_on > Date.today
        row += ["Y", "Pending", "Pending", "Pending", "Pending"]
      elsif p.alsquiznr.blank?
        row += ["N", "NA", "NA", "NA", "NA"]
      else
        row += ["Y", p.alsinterestlevel, p.alsreadlevel, p.alspoints, p.alsquiznr]
      end
      # Reading Counts data
      row += ["N", "NA", "NA", "NA", "NA"]
      # Other
      row += [(p.lexile.blank? ? "N" : p.lexile), (p.guided_level.blank? ? "NA" : p.guided_level)]
      row += [p.copyright, p.available_on]
      # Hosted url if hosted format exists
      if CONFIG[:hosted_ebooks_url] && hosted_format = p.product_formats.where(:format_id => 4).first
        row << "#{CONFIG[:hosted_ebooks_url]}#{hosted_format.isbn}"
      else
        row << nil
      end
    end
    row
  end
  
  def self.nyc_header
    ["ISBN (10 digit)", "ISBN-13 (13 digit)", "Publisher's List Price", "School Library Price", "Binding Type", "Book Title and Main Description", "Imprint/Brand Name", "Parent Publisher Name", "Author", "Publication Date"]
  end
  
  def self.nyc_row(p, pf)
    row = [pf.isbn10, pf.isbn13, pf.price_list, pf.price, pf.format.detail, p.name, p.association_value(:collection, :name_extended), p.publisher, p.author, p.copyright]
  end
  
  def self.orderform_header
    ["product id", "product format id", "isbn 10", "isbn 13", "name", "type", "language", "audience", "reading level", "interest level begin", "interest level end", "product form", "product detail", "number of pages", "publication date", "status code", "copyright year", "list price", "s/l price", "publisher", "imprint", "series title", "series id", "dimensions (width x height)", "weight", "dewey", "graphics", "description", "word count", "lexile", "atos quiz number", "atos points", "atos reading level", "atos interest level", "bisac subject code 1", "bisac subject code 2", "bisac subject code 3", "author", "product_name_with_count", "parts", "is_processed", "units", "alsquiz_count"]
  end
  
  def self.orderform_row(p, pf, date = nil)
    row = [p.id, pf.id, pf.isbn10str, pf.isbn13str, p.name, Product::TYPES[p.class.to_s], p.language, translate(p, :audience, :value), p.reading_level.try(:abbreviation), p.interest_level_min.try(:abbreviation), p.interest_level_max.try(:abbreviation), pf.format.form, pf.format.detail, p.pages, p.available_on.try(:to_s, :us), translate(pf, :status, :value), p.copyright]
    row += [pf.price_list_on(date), pf.price_on(date)]
    row += [p.publisher, p.imprint, p.association_value(:collection, :name), p.collection_id, pf.dimensions, (pf.weight.nil? || pf.weight == 0 ? "" : pf.weight), p.dewey, p.graphics, p.description, p.word_count, p.lexile, p.alsquiznr, p.alspoints, p.alsreadlevel, p.alsinterestlevel]
    row += get_bisacs(p, 3)
    title_count = nil
    if p.is_a?(Assembly)
      title_count = p.titles.includes(:product_formats).where("product_formats.format_id = ?", pf.format_id).count
    end
    row += [p.author_inverted, (title_count ? "#{p.name} (#{title_count} titles)" : "    #{p.name}"), (title_count ? title_count : 1), pf.format.is_processed, pf.format.units, p.alsquiz_count]
  end

  def self.price_change_header
    ["ISBN 13", "Product Name", "Type", "Format", "Series", "List Price Old", "List Price New", "S/L Price Old", "S/L Price New", "Date Effective"]
  end
  
  def self.price_change_row(p, pf)
    # Present the last price change that has yet to be implemented
    if price_change = pf.price_changes.where('state != ?', 'implemented').order(:implement_on).last
      [pf.isbn13, p.name, Product::TYPES[p.class.to_s], pf.to_s, p.association_value(:collection, :name_extended), pf.price_list, price_change.price_list, pf.price, price_change.price, price_change.implement_on]
    else
      nil
    end
  end
  
  def self.replist_header
    ['Title', 'Series', 'Hardcover ISBN', 'Paperback ISBN', 'PDF ISBN', 'Hosted Ebook ISBN', 'List Price', 'S/L Price', 'Interest Level', 'Dewey', 'ATOS', 'Lexile', 'GRL', 'Author', 'Type', 'Date Available']
  end
  
  def self.replist_row(p, pf, date = nil)
    if p.is_a?(Assembly)
      title_count = p.titles.includes(:product_formats).where("product_formats.format_id = ?", pf.format_id).count
      name = "#{p.name} (#{title_count} titles)"
    else
      title_count = 1
      name = "    #{p.name}"
    end
    row = [name, p.association_value(:collection, :name_extended), p.association_value(:default_format, :isbn13str), p.association_value(:trade_format, :isbn13str), p.association_value(:pdf_format, :isbn13str), p.product_formats.where(:format_id => 4).first.try(:isbn13str), p.association_value(:default_format, :price_list), p.association_value(:default_format, :price), p.interest_level_range, p.dewey, p.alspoints, p.lexile, p.guided_level, p.author, Product::TYPES[p.class.to_s], p.available_on]
  end

  def self.sebco_header
    ["Title", "Hardcover ISBN 13", "Code #", "Series Name", "Series Code #", "Interest Levels", "Reading Levels", "Dewey Number", "Author", "Copyright", "Length", "Trim Size", "Binding", "List Price", "Library Price", "Book Awards", "ATOS RL", "ATOS Points", "ATOS Quiz #", "Reading Counts Level", "Reading Count Points", "Summary", "Book Reviews", "Sources", "Book Illustrator ", "ATOS Interest Level", "Book Subjects", "Learning Aids", "Book Imprint", "Authors", "Pages", "ISBN 10", "PB/HB/LB", "Publishing Date", "Guided Reading Level", "Language", "General Image", "Thumbnail Image", "URL", "Ebook ISBN 13", "Paperback ISBN 13", "Interactive ISBN 13"]
  end
  
  def self.sebco_row(p, pf)
    row = [p.name, p.association_value(:default_format, :isbn), nil, p.association_value(:collection, :name_extended), nil, (!p.interest_level_min_id.blank? && !p.interest_level_max_id.blank? ? (p.interest_level_min_id..p.interest_level_max_id).to_a.map{|i| Level.find(i).try(:abbreviation) rescue nil}.compact.join(', ') : ""), p.association_value(:reading_level, :abbreviation), p.dewey, p.author_inverted, p.copyright, nil, pf.dimensions, pf.format.detail, pf.price_list, pf.price, nil, p.alsreadlevel, p.alspoints, p.alsquiznr, nil, nil, p.description, nil, nil, p.illustrator_inverted, p.alsinterestlevel, get_subjects(p, 5).delete_if{|x| x.blank?}.join(', '), nil, p.imprint, nil, p.pages, pf.isbn10, nil, p.available_on.try(:to_s, :us), p.guided_level, p.language]
    rel = "images/covers/l/#{p.isbn}.jpg"
    cover_url = File.exist?(Rails.root.join("public", rel)) ? File.join(CONFIG[:app_url], rel) : nil
    rel = "images/covers/m/#{p.isbn}.jpg"
    thumbnail_url = File.exist?(Rails.root.join("public", rel)) ? File.join(CONFIG[:app_url], rel) : nil
    product_url = File.join(CONFIG[:app_url], "shop/show/#{p.id}")
    row += [cover_url, thumbnail_url, product_url]
    row += [p.association_value(:pdf_format, :isbn), p.association_value(:trade_format, :isbn), nil]
    row
  end

  def self.sebcoebook_header
    ["Title", "Ebook ISBN 13", "Code #", "Series Name", "Series Code #", "Interest Levels", "Reading Levels", "Dewey Number", "Author", "Copyright", "Length", "Trim Size", "Binding", "List Price", "Library Price", "Book Awards", "ATOS RL", "ATOS Points", "ATOS Quiz #", "Reading Counts Level", "Reading Count Points", "Summary", "Book Reviews", "Sources", "Book Illustrator ", "ATOS Interest Level", "Book Subjects", "Learning Aids", "Book Imprint", "Authors", "Pages", "ISBN 10", "PB/HB/LB", "Publishing Date", "Guided Reading Level", "Language", "General Image", "Thumbnail Image", "URL", "Hardcover ISBN 13", "Paperback ISBN 13", "Interactive ISBN 13"]
  end
  
  def self.sebcoebook_row(p, pf)
    row = [p.name, p.association_value(:pdf_format, :isbn), nil, p.association_value(:collection, :name_extended), nil, (!p.interest_level_min_id.blank? && !p.interest_level_max_id.blank? ? (p.interest_level_min_id..p.interest_level_max_id).to_a.map{|i| Level.find(i).try(:abbreviation) rescue nil}.compact.join(', ') : ""), p.association_value(:reading_level, :abbreviation), p.dewey, p.author_inverted, p.copyright, nil, pf.dimensions, pf.format.detail, pf.price_list, pf.price, nil, p.alsreadlevel, p.alspoints, p.alsquiznr, nil, nil, p.description, nil, nil, p.illustrator_inverted, p.alsinterestlevel, get_subjects(p, 5).delete_if{|x| x.blank?}.join(', '), nil, p.imprint, nil, p.pages, pf.isbn10, nil, p.available_on.try(:to_s, :us), p.guided_level, p.language]
    rel = "images/covers/l/#{p.isbn}.jpg"
    cover_url = File.exist?(Rails.root.join("public", rel)) ? File.join(CONFIG[:app_url], rel) : nil
    rel = "images/covers/m/#{p.isbn}.jpg"
    thumbnail_url = File.exist?(Rails.root.join("public", rel)) ? File.join(CONFIG[:app_url], rel) : nil
    product_url = File.join(CONFIG[:app_url], "shop/show/#{p.id}")
    row += [cover_url, thumbnail_url, product_url]
    row += [p.association_value(:default_format, :isbn), p.association_value(:trade_format, :isbn), nil]
    row
  end

  # ONIX export handler
  def self.xml(product_formats, file_path, options = {})
    template = options[:data_template]
    File.open(file_path, "w") do |output|
      header = ONIX::Header.new
      header.from_company = CONFIG[:company_name]
      header.from_person  = CONFIG[:onix_contact]
      header.from_email  = CONFIG[:onix_email]
      header.sent_date = Time.now
      header.default_currency_code = 'USD'
      header.default_price_type_code = 1
      header.default_language_of_text = 'eng'
      header.default_class_of_trade = 'gen'
      writer = ONIX::Writer.new(output, header)

      product_formats.each do |pf|
        p = pf.product
        Rails.logger.warn("# WARN: #{p.name} #{pf.to_s} (#{pf.id}) -- ISBN undefined") if pf.isbn.blank?
        product = ONIX::Product.new

        # PR.1 Record reference number, type, source
        product.record_reference = pf.id

        # PR.1.2 Notification or update type code
        if p.upcoming? || p.tba?
          product.notification_type = 2  # advance notification
        else
          product.notification_type = 3  # notification confirmed
        end

        # PR.2.7 ProductIdentifier
        pid = ONIX::ProductIdentifier.new
        pid.product_id_type = 1
        pid.id_value = pf.id
        product.product_identifiers << pid
        if pf.is_isbn_valid?
          # ISBN 10 is disabled
          # pid = ONIX::ProductIdentifier.new
          # pid.product_id_type = 2
          # pid.id_value = pf.isbn10
          # product.product_identifiers << pid
          pid = ONIX::ProductIdentifier.new
          pid.product_id_type = 15
          pid.id_value = pf.isbn13
          product.product_identifiers << pid
        end
        # Set lccn for default_format only (library binding)
        unless pf.format_id != Format::DEFAULT_ID || p.lccn.blank?
          pid = ONIX::ProductIdentifier.new
          pid.product_id_type = 13
          pid.id_value = p.lccn
          product.product_identifiers << pid
        end

        # PR.3 Product form
        product_form = translate(pf.format, :form, :onix)
        product.product_form = product_form unless product_form.blank?
        product_form_detail = translate(pf.format, :detail, :onix)
        product.product_form_details = product_form_detail unless product_form_detail.blank?
        product.product_packaging = 0 if p.respond_to?(:titles)
        product.number_of_pieces = p.titles.count if p.respond_to?(:titles)
        # TODO: ProductContentType, for use with digital product_form
        # List 81: 07 = still images, 10 = text
        # product.product_content_type = [7, 10] # for digital product_form
        if p.respond_to?(:titles) && p.titles.count < 50
          p.titles.each do |t|
            raise unless tf = t.product_formats.where(:format_id => pf.format_id).first
            item = ONIX::ContainedItem.new
            pid = ONIX::ProductIdentifier.new
            pid.product_id_type = 15
            pid.id_value = tf.isbn13
            item.product_identifiers << pid
            # Withhold form data, seems redundant
            #product_form = translate(tf.format, :form, :onix)
            #item.product_form = product_form unless product_form.blank?
            #product_form_detail = translate(tf.format, :detail, :onix)
            #item.product_form_details = product_form_detail unless product_form_detail.blank?
            item.item_quantity = 1
            product.contained_items << item
          end
        end

        # PR.4 Epublication
        # Note: Used only when the <ProductForm> code is DG
        if product_form == 'DG'
          epub_type = translate_value(pf.format.detail, APP_EPUBS, :onix)
          product.epub_type = epub_type unless epub_type.blank?
        end

        # PR.5 Series
        if p.collection
          series = ONIX::Series.new
          #series.title_of_series = p.collection.name_extended  # Favor title composite
          t = ONIX::Title.new
          t.title_type = 1
          t.title_text = p.collection.name_extended
          series.titles << t
          pid = ONIX::SeriesIdentifier.new
          pid.series_id_type = 1
          pid.id_value = p.collection_id
          series.series_identifiers << pid
          product.series << series
        end

        # PR.6 Set
        if options[:data_class] != 'Title' && p.is_a?(Title) && p.assemblies.any?
          p.assemblies.each do |assembly|
            # Caveat: Assuming assemblies only contain like formatted items
            # Eg, a pdf title can only be a part of a pdf assembly
            if apf = assembly.product_formats.find_by_format_id(pf.format_id)
              set = ONIX::Set.new
              #set.title_of_set = "#{assembly.name} (Set)"  # Favor title composite
              t = ONIX::Title.new
              t.title_type = 1
              t.title_text = assembly.title.blank? ? assembly.name : assembly.title
              t.title_text = "#{t.title_text} (Set)"
              t.subtitle = assembly.subtitle unless assembly.subtitle.blank?
              set.titles << t
              pid = ONIX::ProductIdentifier.new
              pid.product_id_type = 1
              pid.id_value = apf.id
              set.product_identifiers << pid
              if apf.is_isbn_valid?
                pid = ONIX::ProductIdentifier.new
                pid.product_id_type = 15
                pid.id_value = apf.isbn13 # must not contain hyphens
                set.product_identifiers << pid
              end
              product.sets << set
            end
          end
        end

        # PR.7 Title
        t = ONIX::Title.new
        t.title_type = 1
        t.title_text = p.title.blank? ? p.name : p.title
        t.title_text = "#{t.title_text} (Set)" if p.is_a?(Assembly)
        t.subtitle = p.subtitle unless p.subtitle.blank?
        product.titles << t

        # PR.7.15 WorkIdentifier
        wid = ONIX::WorkIdentifier.new
        wid.work_id_type = 1
        wid.id_value = p.id
        product.work_identifiers << wid

        # PR.7.18 Website composite for work composite
        if CONFIG[:app_url]
          w = ONIX::Website.new
          w.website_role = 2  # site for specified work
          w.website_link = File.join(CONFIG[:app_url], "shop/show/#{p.id}")
          product.websites << w
        end

        # PR.8 Authorship
        p.contributors.each do |contributor|
          ContributorAssignment.where(:product_id => p.id).where(:contributor_id => contributor.id).all.map(&:role).each do |role|
            onix_role = APP_ROLES[role]['onix']
            onix_role = Array(onix_role) if onix_role.is_a?(String)
            onix_role.each do |role|
              c = ONIX::Contributor.new
              c.sequence_number = product.contributors.size + 1
              c.contributor_role = role
              c.person_name_inverted = contributor.name_inverted
              product.contributors << c
            end
          end
        end

        # PR.11 Language
        language_code = translate(p, :language, :onix)
        unless language_code.blank?
          l = ONIX::Language.new
          l.language_role = 1
          l.country_code = "US" if language_code == "eng"
          l.language_code = language_code
          product.languages << l
        end

        # PR.12 Extents and other content
        product.number_of_pages = p.pages

        # PR.13 Subject

        # The first bisac is the most specific
        main_bisac_code = (p.bisac_subjects.any? ? p.bisac_subjects.first.code : CONFIG[:default_bisac])
        product.basic_main_subject = main_bisac_code

        # Other bisacs defined through subject composite
        p.bisac_subjects.each do |bisac|
          # product.add_bisac_subject(bisac.code) unless bisac.code == main_bisac_code
          unless bisac.code = main_bisac_code
            s = ONIX::Subject.new
            s.subject_scheme_id = 10  # Bisac
            s.subject_code = bisac.code
            product.subjects << s
          end
        end

        unless p.dewey.blank?
          s = ONIX::Subject.new
          s.subject_scheme_id = 1  # Dewey
          s.subject_code = p.dewey
          product.subjects << s
        end

        # PR.14 Audience

        audience_code = translate(p, :audience, :onix)
        product.audience_codes = audience_code unless audience_code.blank?

        unless p.lexile.blank?
          # Ingram way to define Lexile -- to be deprecated by ONIX 3.0
          c = ONIX::Complexity.new
          c.complexity_scheme_identifier = 2
          c.complexity_code = p.lexile
          product.complexities << c
          # New way to define Lexile
          a = ONIX::Audience.new
          a.audience_code_type = 19
          a.audience_code_value = p.lexile
          product.audiences << a
        end

        interest_level_min = p.association_value(:interest_level_min, :abbreviation)
        interest_level_max = p.association_value(:interest_level_max, :abbreviation)
        unless (interest_level_min.blank? || interest_level_max.blank?)
          a = ONIX::AudienceRange.new
          a.audience_range_qualifier = 11  # US school grade range
          a.audience_range_precisions = [3, 4]  # From, To
          a.audience_range_values << interest_level_min
          a.audience_range_values << interest_level_max
          product.audience_ranges << a
        end

        # PR.15 Descriptions and other supporting text
        # Main description
        unless p.description.blank?
          txt = ONIX::OtherText.new
          txt.text_type_code = 1
          txt.text = p.description
          product.other_texts << txt
        end
        # Short description
        unless p.annotation.blank?
          txt = ONIX::OtherText.new
          txt.text_type_code = 2
          txt.text = p.annotation
          product.other_texts << txt
        end
        # Table of contents
        # unless p.toc.blank?
        #   txt = ONIX::OtherText.new
        #   txt.text_type_code = 4
        #   txt.text = p.toc
        #   product.other_texts << txt
        # end
        # Promotional text
        unless p.spotlight_description.blank?
          txt = ONIX::OtherText.new
          txt.text_type_code = 35
          txt.text = p.spotlight_description
          product.other_texts << txt
        end

        # PR.16 Links to image/audio/video files
        # Note:
        # 1. Intentionally using p.isbn, which is the default format isbn, to obtain product format image
        # 2. Assuming jpg format

        # High-quality cover image
        # rel = "covers/#{p.isbn}.jpg"
        # url = nil
        # if CONFIG[:ftp_site]
        #   ftp_domain = CONFIG[:ftp_site].gsub('ftp://', '')
        #   credentials = nil
        #   if CONFIG[:ftp_user] && CONFIG[:ftp_password]
        #     credentials = "#{CONFIG[:ftp_user]}:#{CONFIG[:ftp_password]}@"
        #   end
        #   url = %Q(ftp://#{credentials}#{File.join(ftp_domain, "images", rel)})
        # end
        # if url && File.exist?(File.join(CONFIG[:image_archive_dir], rel))
        #   mf = ONIX::MediaFile.new
        #   mf.media_file_type_code = 6  # high-quality
        #   # mf.media_file_format_code = 3  # jpg
        #   mf.media_file_link_type_code = 5  # ftp
        #   mf.media_file_link = url
        #   product.media_files << mf
        # end

        # Normal cover image
        rel = "images/covers/l/#{p.isbn}.jpg"
        url = nil
        if CONFIG[:app_url]
          url = File.join(CONFIG[:app_url], rel)
        end
        if url && File.exist?(File.join(Rails.public_path, rel))
          mf = ONIX::MediaFile.new
          mf.media_file_type_code = 4  # standard (not high-quality, which is 6)
          # mf.media_file_format_code = 3  # jpg
          mf.media_file_link_type_code = 1  # uri
          mf.media_file_link = url
          product.media_files << mf
        end

        # Thumbnail cover image
        rel = "images/covers/m/#{p.isbn}.jpg"
        url = nil
        if CONFIG[:app_url]
          url = File.join(CONFIG[:app_url], rel)
        end
        if url && File.exist?(File.join(Rails.public_path, rel))
          mf = ONIX::MediaFile.new
          mf.media_file_type_code = 7  # standard (not high-quality, which is 6)
          # mf.media_file_format_code = 3  # jpg
          mf.media_file_link_type_code = 1  # uri
          mf.media_file_link = File.join(CONFIG[:app_url], rel)
          product.media_files << mf
        end

        # PR.16.15 Product website composite
        # Note: Using Website composite for work instead
        # if CONFIG[:app_url]
        #   w = ONIX::ProductWebsite.new
        #   w.website_role = 2  # site for specified work
        #   w.product_website_link = File.join(CONFIG[:app_url], "shop/show/#{p.id}")
        #   product.product_websites << w
        # end

        # PR.19.2 Imprint composite
        # Note: Select distributors require imprint, use publisher as default
        imprint = p.imprint.blank? ? p.publisher : p.imprint
        unless imprint.blank?
          x = ONIX::Imprint.new
          x.imprint_name = imprint
          product.imprints << x
        end

        # PR.19.7 Publisher composite
        unless p.publisher.blank?
          x = ONIX::Publisher.new
          x.publishing_role = 1
          x.publisher_name = p.publisher
          product.publishers << x
        end

        # PR.20 Publishing status and dates, and copyright
        product.publishing_status = translate(pf, :status, :onix).to_i # List 64
        if options[:data_deactivate_sets] && p.is_a?(Assembly)
          product.publishing_status = 8  # Inactive
        end
        # product.announcement_date = p.available_on - 4.months if p.available_on
        product.publication_date = p.available_on
        product.copyright_year = p.copyright

        # PR.21 Territorial rights and other sales restrictions
        sr = ONIX::SalesRights.new
        sr.sales_rights_type = 2
        # sr.rights_countries = ["CA", "US"]
        sr.rights_territories = ["WORLD"]
        product.sales_rights << sr

        # PR.21.5 Not for sale composite
        # nfs = ONIX::NotForSale.new
        # nfs.rights_countries = ["NZ"]
        # product.not_for_sales << nfs

        # PR.21.13 Sales restriction composite
        # sr = ONIX::SalesRestriction.new
        # sr.sales_restriction_type = 0  # not applicable to s/l market
        # product.sales_restrictions << sr

        # PR.22 Dimensions
        if pf.height && pf.height > 0
          height = ONIX::Measure.new
          height.measure_type_code = 1
          height.measure_unit_code = "in"
          height.measurement = pf.height
          product.measures << height
        end
        if pf.width && pf.width > 0
          width = ONIX::Measure.new
          width.measure_type_code = 2
          width.measure_unit_code = "in"
          width.measurement = pf.width
          product.measures << width
        end
        if pf.weight && pf.weight > 0
          weight = ONIX::Measure.new
          weight.measure_type_code = 8
          weight.measure_unit_code = "oz"
          weight.measurement = pf.weight
          product.measures << weight
        end

        # PR.23 Related products

        # If product has replacement
        if replacement = p.replacement
          # and product replacement has same format as current product format
          if rpf = replacement.product_formats.find_by_format_id(pf.format_id)
            rp = ONIX::RelatedProduct.new
            rp.relation_code = 5  # replaced by
            pid = ONIX::ProductIdentifier.new
            pid.product_id_type = 1
            pid.id_value = rpf.id
            rp.product_identifiers << pid
            product.related_products << rp
          end
        end

        # If product has similarities
        p.similar_products.each do |sp|
          if spf = sp.product_formats.find_by_format_id(pf.format_id)
            rp = ONIX::RelatedProduct.new
            rp.relation_code = 23  # similar to
            pid = ONIX::ProductIdentifier.new
            pid.product_id_type = 1
            pid.id_value = spf.id
            rp.product_identifiers << pid
            product.related_products << rp
          end
        end

        # PR.24 Supplier, availability and prices
        sd = ONIX::SupplyDetail.new
        sd.supplier_name = CONFIG[:company_name]
        sd.telephone_number = CONFIG[:phone]
        sd.fax_number = CONFIG[:fax]
        sd.email_address = CONFIG[:sales_email]
        # sd.supply_to_countries = "CA US"  # space-separated list
        sd.supply_to_territories = "WORLD"  # space-separated list
        sd.supplier_role = 1  # Publisher to retailers
        sd.product_availability = pf.availability # List 65
        if options[:data_deactivate_sets] && p.is_a?(Assembly)
          sd.product_availability = 50  # Not sold as set
        end
        sd.on_sale_date = p.available_on

        # S/L price
        if options[:data_include_sl_price]
          price = ONIX::Price.new
          price.price_amount = pf.price
          price.price_type_code = 1
          price.price_type_description = 'School/library market price'
          price.class_of_trade = 'sl'
          # price.country_codes = 'CA US'
          price.territories = 'WORLD'
          price.price_qualifier = 6
        end

        # List price, WORLD
        price_list = ONIX::Price.new
        price_list.price_amount = pf.price_list
        price_list.price_type_code = 1
        price_list.price_type_description = 'General trade market list price'
        # price_list.country_codes = 'CA US'
        price_list.territories = 'WORLD'
        price_list.countries_excluded = 'GB' if CONFIG[:csplus_discount_code]

        # List price, Great Britain
        if CONFIG[:csplus_discount_code]
          price_gb = ONIX::Price.new
          price_gb.currency_code = 'GBP'
          price_gb.price_amount = pf.price_foreign('GBP')
          price_gb.price_type_code = 1
          price_gb.country_codes = 'GB'
        end

        # Agency price
        if options[:data_include_agency_price]
          price_agency = ONIX::Price.new
          price_agency.price_amount = pf.price_agency
          price_agency.price_type_code = 41
          price_agency.price_type_description = 'Agency price'
          # price_agency.country_codes = 'CA US'
          price_agency.territories = 'WORLD'
        end

        # Coresource Plus discount code to be applied to List Prices only
        if CONFIG[:csplus_discount_code]
          dc = ONIX::DiscountCoded.new
          dc.discount_code_type = 2
          dc.discount_code = CONFIG[:csplus_discount_code]
          dc.discount_code_type_name = 'CSPLUS'
          price_list.discount_codeds << dc
          price_gb.discount_codeds << dc
        end

        # Present the last price change that has yet to be implemented
        if options[:data_include_price_change] && price_change = pf.price_changes.where('state != ?', 'implemented').order(:implement_on).last
          # Duplicate prices, use price_change value
          new_price = price.dup if options[:data_include_sl_price]
          new_price_list = price_list.dup
          new_price_gb = price_gb.dup if CONFIG[:csplus_discount_code]
          new_price_agency = price_agency.dup if options[:data_include_agency_price]
          # Update prices
          new_price.price_amount = price_change.price if options[:data_include_sl_price]
          new_price_list.price_amount = price_change.price_list
          new_price_gb.price_amount = price_change.price_foreign('GBP') if CONFIG[:csplus_discount_code]
          new_price_agency.price_amount = price_change.price_agency if options[:data_include_agency_price]
          # Restrict dates on new prices
          new_price.price_effective_from = price_change.implement_on if options[:data_include_sl_price]
          new_price_list.price_effective_from = price_change.implement_on
          new_price_gb.price_effective_from = price_change.implement_on if CONFIG[:csplus_discount_code]
          new_price_agency.price_effective_from = price_change.implement_on if options[:data_include_agency_price]
          # Restrict dates on original prices
          price.price_effective_until = price_change.implement_on - 1.day if options[:data_include_sl_price]
          price_list.price_effective_until = price_change.implement_on - 1.day
          price_gb.price_effective_until = price_change.implement_on - 1.day if CONFIG[:csplus_discount_code]
          price_agency.price_effective_until = price_change.implement_on - 1.day if options[:data_include_agency_price]
          # Add new prices to supply detail
          sd.prices << new_price if options[:data_include_sl_price]
          sd.prices << new_price_list
          sd.prices << new_price_gb if CONFIG[:csplus_discount_code]
          sd.prices << new_price_agency if options[:data_include_agency_price]
        end
        # Add original prices to supply detail
        sd.prices << price if options[:data_include_sl_price]
        sd.prices << price_list
        sd.prices << price_gb if CONFIG[:csplus_discount_code]
        sd.prices << price_agency if options[:data_include_agency_price]

        # Add supply details
        product.supply_details << sd

        writer << product
      end
      writer.end_document
    end
    doc = File.read(file_path)
    # This is a kludge to fix AudienceRange tag
    doc.gsub!(/  <AudienceRange>\n    <AudienceRangeQualifier>(.*?)<\/AudienceRangeQualifier>\n    <AudienceRangePrecision>(.*?)<\/AudienceRangePrecision>\n    <AudienceRangePrecision>(.*?)<\/AudienceRangePrecision>\n    <AudienceRangeValue>(.*?)<\/AudienceRangeValue>\n    <AudienceRangeValue>(.*?)<\/AudienceRangeValue>\n  <\/AudienceRange>/) {|s| "  <AudienceRange>\n    <AudienceRangeQualifier>#{$1}<\/AudienceRangeQualifier>\n    <AudienceRangePrecision>#{$2}<\/AudienceRangePrecision>\n    <AudienceRangeValue>#{$4}<\/AudienceRangeValue>\n    <AudienceRangePrecision>#{$3}<\/AudienceRangePrecision>\n    <AudienceRangeValue>#{$5}<\/AudienceRangeValue>\n  <\/AudienceRange>"}
    File.open(file_path, 'w') {|f| f.write(doc) }
    return file_path
  end
  
  def self.get_contributors(product, qty)
    col = []
    n = 0
    product.contributor_assignments.each do |assignment|
      break if n >= qty
      col << Name.inverted(assignment.contributor.name)
      col << assignment.role
      n += 1
    end
    (qty - n).times { |i| col += ["", ""] }
    col
  end
  
  def self.get_bisacs(product, qty)
    col = []
    bisacs = product.bisac_subjects.map(&:code)
    qty.times { |i| col << (bisacs[i].nil? ? '' : bisacs[i]) }
    col
  end
  
  def self.get_subjects(product, qty)
    col = []
    subjects = product.subjects
    qty.times { |i| col << (subjects[i].nil? ? '' : subjects[i]) }
    col
  end
  
  def self.translate(inst, meth, version)
    meth = meth.to_sym
    meth_map = {:reading_level_id => :grade, :interest_level_min_id => :grade, :interest_level_max_id => :grade, :default_role => :role}
    list_name = (meth_map.has_key?(meth) ? meth_map[meth] : meth)
    list = "APP_#{list_name.to_s.pluralize.upcase}".constantize
    key = inst.send(meth)
    translate_value(key, list, version)
  end
  
  def self.translate_value(value, list, version)
    list.has_key?(value) ? list[value][version.to_s] : ''
  end
  
end

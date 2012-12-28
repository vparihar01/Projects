namespace :import do
  require 'rake_utils'

  desc "Import products data. If product already exists, product is updated. Default file is 'products.csv'. Override using command line parameter 'file=value'. File must be in 'tmp/import/' directory. 'mac=[true|FALSE]', 'delete=[true|FALSE]', 'verbose=[TRUE|false]'."
  task :products => :environment do
    require 'products_parser'
    debug = RakeUtils.str_to_boolean(ENV['debug'], :default => false)
    verbose = RakeUtils.str_to_boolean(ENV['verbose'], :default => true)
    mac = RakeUtils.str_to_boolean(ENV['mac'], :default => false)
    delete = RakeUtils.str_to_boolean(ENV['delete'], :default => false)
    archive = RakeUtils.str_to_boolean(ENV['archive'], :default => true)
    file = ENV['file'].blank? ? 'products.csv' : ENV['file']
    RakeUtils.print_variable(%w(debug verbose mac delete file), binding) if verbose
    
    # delete if requested
    if delete
      # Don't delete any table that has a proprietary_id field. Those can be updated.
      %w(assembly_assignments bisac_assignments categories_products collections contributor_assignments products product_formats).each do |table|
        sql = "DELETE FROM #{table}"
        if debug
          puts sql
        else
          ActiveRecord::Base.connection.delete(sql)
        end
      end
    end

    # import the file using lib/products_parser.rb
    ProductsParser.execute(Rails.root.join('tmp/import', file), :debug => debug, :verbose => verbose, :mac => mac, :archive => archive)
  end

  desc "Import teaching guides. Place files in #{Rails.root.join('tmp/import/teaching_guides')}. Options: overwrite, archive."
  task :activities => :environment do
    # process command line parameters
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['debug'], :default => true))
    overwrite = Coverpage::Utils.str_to_boolean(ENV['overwrite'], :default => false)
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    source_dir = Rails.root.join('tmp/import/teaching_guides')
    archive_dir = Rails.root.join('tmp/import/archive')
    Coverpage::Utils.print_variable(%w(overwrite archive source_dir archive_dir), binding)
    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")

    puts "Scanning directory '#{source_dir}'..."
    files = Dir.glob("#{source_dir}/*.pdf")
    puts "Found #{files.size} incoming teaching guides..."

    unless files.empty?
      # only create archive directories if there are files to be processed
      puts "Preparing archive directory..."
      [archive_dir].each {|dir| FileUtils.mkdir_p(dir, :verbose => true) unless File.directory?(dir)}
    end

    # loop through files
    mimetype = 'application/pdf'
    files.each_with_index do |path, i|
      error = false
      # check each file for corresponding product, etc.
      filename = File.basename(path)
      isbn = File.basename(path, '.pdf')
      puts "#{i+1}. #{filename}"
      unless product = Title.find_by_isbn(isbn)
        puts "  Product not found!"
        error = true
      end
      puts "  Product found: '#{product.name}' (#{product.id})..."
      name = "#{product.name}: Activities"
      teaching_guide = TeachingGuide.find_by_name(name)
      data = {:name => name, :body => "Activities presented in the book '#{product.name}'", :rationale => '', :objective => '', :tag_list => 'activities', :path => path, :mimetype => mimetype}
      if teaching_guide
        if overwrite
          puts "  Updating Teaching Guide..."
          unless debug
            teaching_guide.update_with_local_file(data)
            teaching_guide.products << product unless teaching_guide.products.include?(product)
          end
        else
          puts "  Teaching Guide already exists (overwrite disabled): Skipping..."
          error = true
        end
      else
        puts "  Creating Teaching Guide..."
        begin
          teaching_guide = TeachingGuide.create_with_local_file(data) unless debug
          if !debug && teaching_guide
            teaching_guide.products << product
          end
        rescue
          puts "  Failed!"
          error = true
        end
      end
      unless error
        # Archive the processed import file
        target = "teaching_guide-#{isbn}-#{timestamp}.pdf"
        FileUtils.mv(path, File.join(archive_dir, target), :noop => debug, :verbose => verbose, :force => true) if archive
      end
    end
  end

  desc "Import Ebook pdf's. Default source directory, archive directory and overwrite value are defined in CONFIG (ebook_import_source_dir, ebook_import_archive_dir, ebook_import_overwrite). Directories must be in 'Rails.root'. Optional: source=[#{CONFIG[:ebook_import_source_dir]}], archive=[#{CONFIG[:ebook_import_archive_dir]}], overwrite=[true|FALSE]."
  task :ebooks => :environment do
    # process command line parameters
    source = ENV['source'].blank? ? CONFIG[:ebook_import_source_dir] : ENV['source']
    archive = ENV['archive'].blank? ? CONFIG[:ebook_import_archive_dir] : ENV['archive']
    overwrite = RakeUtils.str_to_boolean(ENV['overwrite'], :default => false)
    RakeUtils.print_variable(%w(overwrite source archive), binding)

    puts "Scanning directory '#{source}'..."
    files = Dir.glob(Rails.root.join(source, "*.pdf"))
    puts "Found #{files.size} incoming ebooks..."

    unless files.empty?
      # only create archive directories if there are files to be processed
      puts "Preparing archive directory..."
      archive_dir = Rails.root.join(archive)
      unknown_dir = Rails.root.join(CONFIG[:ebook_import_unknown_dir])
      bad_dir = Rails.root.join(CONFIG[:ebook_import_bad_dir])
      [archive_dir, unknown_dir, bad_dir].each {|dir| FileUtils.mkdir_p(dir, :verbose => true) unless File.directory?(dir)}
    end

    # loop through files
    mimetype = "application/pdf"
    files.each_with_index do |path, i|
      # check each file for corresponding product, etc.
      filename = File.basename(path)
      isbn = File.basename(path, '.pdf')
      puts "#{i+1}. #{filename}"
      unless product = Title.find_by_isbn(isbn)
        puts "  Product not found!"
        FileUtils.mv(path, unknown_dir)
        next
      end
      puts "  Product found: '#{product.name}' (#{product.id})..."
      Rails.logger.debug("id --- #{product.id.inspect}")
      Rails.logger.debug("collection_id --- #{product.collection_id.inspect}")
      if !product.download || overwrite
        begin
          product.create_download_with_local_file(path)
        rescue
          puts "  Failed!"
          FileUtils.mv(path, bad_dir)
          next
        end
      else
        puts "  Download already exists (overwrite disabled): Skipping..."
      end
      # archive the processed import file.
      puts "  Archiving file..."
      FileUtils.mv(path, archive_dir)
    end
    puts "Finished processing incoming ebooks."
  end

  desc "Import bisac data. Default file is 'bisac_subjects.csv'. Override using command line parameter 'file=value'. File must be in 'Rails.root/tmp/import' directory. Default import behavior is to truncate table. Options: truncate=[TRUE|false], verbose=[true|FALSE]."
  task :bisac_subjects => :environment do
    require 'importer'

    # process command line parameters
    file = ENV['file'].blank? ? 'bisac_subjects.csv' : ENV['file']
    truncate = RakeUtils.str_to_boolean(ENV['truncate'], :default => true)
    verbose = RakeUtils.str_to_boolean(ENV['verbose'], :default => false)
    RakeUtils.print_variable(%w(verbose file truncate), binding)
    puts "Importing #{file} (truncate = #{truncate})..."

    # import the file using lib/products_parser.rb
    Importer.import_file(file, 'bisac_subjects', { 'Code' => 'code', 'Literal' => 'literal', 'Seq' => 'seq', 'Trans' => 'trans','Comments' => 'comments' }, truncate)
  end

  desc "Import Accelerated Learner data. Default file is 'ar_list.csv'. Override using command line parameter 'file=value'. File must be in 'Rails.root/tmp/import' directory. Optional: debug, verbose, file, archive'."
  task :ar_list => :environment do

    # process command line parameters
    file = ENV['file'].blank? ? 'ar_list.csv' : ENV['file']
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    Coverpage::Utils.print_variable(%w(debug verbose file archive), binding)

    # FIELDS: quiz, lang, title, authorfirst, authorlast, approved, il, rl, pts, f_nf, publisher, isbns, assembly
    path = Rails.root.join('tmp', 'import', file)
    test = FasterCSV.open(path, :headers => true, :skip_blanks => true, :header_converters => :symbol).each do |row|
      isbns = row[:isbns].split(',')
      isbns.each do |isbn|
        # puts "#{row[:isbns]} => #{isbn}"
        if /^978/.match(isbn)
          isbn = isbn.strip.gsub(/-/, '')
          if product = Title.find_by_isbn(isbn)
            data = {:alsquiznr => row[:quiz], :alsreadlevel => row[:rl], :alspoints => row[:pts], :alsinterestlevel => row[:il]}
            FEEDBACK.debug("  Updating attributes #{data.inspect}...") if verbose
            product.update_attributes(data) unless debug
            (puts product.errors.full_messages) if !debug && product.errors.any?
          end
        end
      end
    end
    # Archiving the file after it's parsed
    Coverpage::Utils.parser_archive(path, :debug => debug, :verbose => verbose) if archive
  end

  desc "Update product formats by ISBN. Default file is 'product_formats.csv'. Override using command line parameter 'file=value'. File must be in 'Rails.root/tmp/import' directory. Optional: debug, verbose, file, mac, archive, isbns."
  task :update_product_formats_by_isbn => :environment do
    require 'importer'

    # process command line parameters
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    file = ENV['file'].blank? ? 'product_formats.csv' : ENV['file']
    mac = Coverpage::Utils.str_to_boolean(ENV['mac'], :default => false)
    isbns = (ENV['isbns'].blank? ? [] : ENV['isbns'].split(',').map{|i| i.strip})
    Coverpage::Utils.print_variable(%w(debug verbose file archive isbns), binding) if verbose
    puts "Importing '#{file}'..." if verbose

    # import the file using lib/importer.rb
    Importer.update_class(file, :debug => debug, :verbose => verbose, :archive => archive, :table => "product_formats", :by => "isbn", :mac => mac, :restrict => isbns)
  end

  desc "Update products by ISBN. Default file is 'products.csv'. Override using command line parameter 'file=value'. File must be in 'Rails.root/tmp/import' directory. Optional: debug, verbose, file, archive"
  task :update_products_by_isbn => :environment do
    require 'importer'

    # process command line parameters
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    file = ENV['file'].blank? ? 'products.csv' : ENV['file']
    Coverpage::Utils.print_variable(%w(debug verbose file archive), binding) if verbose
    puts "Importing '#{file}'..." if verbose

    # import the file using lib/importer.rb
    Importer.update_class(file, :debug => debug, :verbose => verbose, :archive => archive, :table => "products", :by => "isbn")
  end

  desc "Update records in table. File must match table name, which must be a Ruby class. Value in first column used to find record (eg, id, isbn). File must be in 'Rails.root/tmp/import' directory. Required: file, by. Optional: debug, verbose, archive"
  task :update_class => :environment do
    require 'importer'

    # process command line parameters
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    file = Coverpage::Utils.impose_requirement(ENV, 'file')
    by = Coverpage::Utils.impose_requirement(ENV, 'by')
    Coverpage::Utils.print_variable(%w(debug verbose file by archive), binding) if verbose
    puts "Importing '#{file}'..." if verbose

    # import the file using lib/importer.rb
    Importer.update_class(file, :debug => debug, :verbose => verbose, :archive => archive, :by => by)
  end

  desc "Import Lexile data. Default file is 'lexile.csv'. Override using command line parameter 'file=value'. File must be in 'Rails.root/tmp/import' directory. Optional: debug, verbose, archive."
  task :lexile => :environment do
    ENV['file'] = 'lexile.csv' unless ENV['file']
    Rake::Task['import:update_products_by_isbn'].invoke
  end

  desc "Import CIP data. Default file is 'cip.csv'. Override using command line parameter 'file=value'. File must be in 'Rails.root/tmp/import' directory. Optional: debug, verbose, archive."
  task :cip => :environment do
    ENV['file'] = 'cip.csv' unless ENV['file']
    Rake::Task['import:update_products_by_isbn'].invoke
  end
  
  desc "Import table of contents data. Files must be in 'Rails.root/tmp/import/tocs' directory, named by ISBN. Optional: debug, verbose, archive."
  task :tocs => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['debug'], :default => true))
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    Coverpage::Utils.print_variable(%w(debug verbose archive), binding) if verbose
    dir_tocs = Rails.root.join("tmp/import/tocs")
    dir_unknown = Rails.root.join("tmp/import/unknown")
    dir_archive = Rails.root.join("tmp/import/archive")
    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    Dir.glob(File.join(dir_tocs, "*.txt")).each do |file|
      isbn = File.basename(file, '.txt')
      target = "toc-#{isbn}-#{timestamp}.txt"
      unless title = Title.find_by_isbn(isbn)
        FEEDBACK.error("Unknown ISBN '#{file}'")
        FileUtils.mv(file, File.join(dir_unknown, target), :noop => debug, :verbose => verbose, :force => true)
        next
      end
      FEEDBACK.print_record(title)
      chapters = []
      File.open(file, 'r').each do |line|
        if result = /(.*)\|(\d+)/.match(line)
          chapters << result[1]
        end
      end
      toc = chapters.join("\n")
      FEEDBACK.debug(toc.inspect)
      title.update_attribute(:toc, toc) unless toc.blank? || debug
      FileUtils.mv(file, File.join(dir_archive, target), :noop => debug, :verbose => verbose, :force => true) if archive
    end
  end
  
  desc "Import CSV data. File name must correspond to table name. Mandatory: table. Options: debug=[true|FALSE], verbose=[TRUE|false], truncate=[true|FALSE], mac=[true|FALSE], archive=[TRUE|false]."
  task :csv => :environment do
    require 'csv_parser'
    debug = RakeUtils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || RakeUtils.str_to_boolean(ENV['debug'], :default => true))
    truncate = RakeUtils.str_to_boolean(ENV['truncate'], :default => false)
    mac = RakeUtils.str_to_boolean(ENV['mac'], :default => false)
    archive = RakeUtils.str_to_boolean(ENV['archive'], :default => true)
    table = RakeUtils.impose_requirement(ENV, 'table')
    RakeUtils.print_variable(%w(debug verbose truncate mac archive table), binding) if verbose
    CsvParser.execute(table, :debug => debug, :verbose => verbose, :truncate => truncate, :mac => mac, :archive => archive)
  end
  
  desc "Import links data provided by production department. Default file is 'links.csv'. Override using command line parameter 'file=value'. File must be in 'Rails.root/tmp/import' directory. Optional: debug=[true|FALSE], verbose=[TRUE|false], archive, file."
  task :links => :environment do
    file = ENV['file'].blank? ? 'links.csv' : ENV['file']
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    Coverpage::Utils.print_variable(%w(debug verbose file archive), binding)

    # FIELDS: proprietary_product_id, title, url, description
    path = Rails.root.join('tmp', 'import', file)
    FasterCSV.open(path, :headers => true, :skip_blanks => true, :header_converters => :symbol).each do |row|
      pid = row[:proprietary_product_id]
      non_data_fields = %w(proprietary_product_id)
      data = row.to_hash.reject{|k,v| v.blank? || non_data_fields.include?(k.to_s)}
      unless link = Link.find_by_url(data[:url])
        # FEEDBACK.debug "Creating link #{data.inspect}..."
        link = Link.create(data) unless debug
      end
      if link.try(:id)
        # FEEDBACK.debug "link = #{link.inspect}"
        if product = Product.find_by_proprietary_id(pid)
          FEEDBACK.verbose "Adding link '#{link.id}' to product '#{product.id}'..." if verbose
          product.links << link unless debug
        else
          FEEDBACK.error "Product not found #{pid}"
          next
        end
      else
        FEEDBACK.error "Failed to find/create url #{row[:url]}"
        next
      end
    end
    FEEDBACK.important "Removing duplicates (this could take a few minutes)... #{Time.now}"
    Link.remove_duplicate_product_assignments
    # Archiving the file after it's parsed
    Coverpage::Utils.parser_archive(path, :debug => debug, :verbose => verbose) if archive
  end
  
  desc "Import pdf format data exported from fmp (fields: ProdIDMaster, PriceListCurrent, PriceSLCurrent, ISBNText, Status). Options: debug, verbose, file."
  task :cw_eisbns => :environment do
    file = ENV['file'].blank? ? 'eisbns.csv' : ENV['file']
    debug = RakeUtils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || RakeUtils.str_to_boolean(ENV['verbose'], :default => true))
    mac = RakeUtils.str_to_boolean(ENV['mac'], :default => false)
    RakeUtils.print_variable(%w(debug verbose file mac), binding)
    
    # FIELDS: ProdIDMaster, PriceListCurrent, PriceSLCurrent, ISBNText, Status
    test = FasterCSV.open(Rails.root.join('tmp', 'import', file), :row_sep => (mac ? "\r" : "\n"), :headers => true, :skip_blanks => true, :header_converters => :symbol).each do |row|
      pid = row[:prodidmaster]
      non_data_fields = %w(prodidmaster)
      data = row.to_hash.reject{|k,v| v.blank? || non_data_fields.include?(k.to_s)}
      if product = Product.find_by_proprietary_id(pid)
        puts "  Product found #{pid}" if verbose
        data = {}
        data[:format_id] = Format::PDF_ID
        data[:price_list] = row[:pricelistcurrent] unless row[:pricelistcurrent].blank?
        data[:price] = row[:priceslcurrent] unless row[:priceslcurrent].blank?
        data[:isbn] = row[:isbntext] unless row[:isbntext].blank?
        data[:status] = row[:status] unless row[:status].blank?
        unless data[:isbn].nil?
          pf = product.product_formats.find_by_format_id(data[:format_id])
          if pf
            puts "  Updating '#{data[:isbn]}'..."
            pf.update_attributes(data) unless debug
          else
            puts "  Creating '#{data[:isbn]}'..."
            product.product_formats.create(data) unless debug
          end
          puts "  #{data.inspect}"
        end
      else
        puts "! Error: Product not found #{pid}" if verbose
        next
      end
    end
  end

  desc "Import non default format data (fields: default_isbn, isbn + other product format fields). Required: format_id. Optional: debug, verbose, file, mac, archive."
  task :isbns => :environment do
    file = ENV['file'].blank? ? 'isbns.csv' : ENV['file']
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    mac = Coverpage::Utils.str_to_boolean(ENV['mac'], :default => false)
    acceptable_format_ids = Format.all.map(&:id).reject {|id| id == Format::DEFAULT_ID}
    format_id = Coverpage::Utils.str_to_choice(ENV['format_id'], acceptable_format_ids, :allow_nil => false)
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    Coverpage::Utils.print_variable(%w(debug verbose file mac format_id archive), binding)
    
    # FIELDS: default_isbn, isbn (, price_list, price, status, weight, dimensions)
    path = Rails.root.join('tmp', 'import', file)
    FasterCSV.open(path, :row_sep => (mac ? "\r" : "\n"), :headers => true, :skip_blanks => true, :header_converters => :symbol).each do |row|
      isbn = row[:default_isbn]
      non_data_fields = %w(default_isbn)
      data = row.to_hash.reject{|k,v| v.blank? || non_data_fields.include?(k.to_s)}
      if product = Product.find_by_isbn(isbn)
        Coverpage::Utils.print_product(product) if verbose
        data[:format_id] = format_id
        unless data[:isbn].nil?
          pf = product.product_formats.find_by_format_id(data[:format_id])
          if pf
            puts "  Updating '#{data[:isbn]}'..."
            pf.update_attributes(data) unless debug
          else
            puts "  Creating '#{data[:isbn]}'..."
            product.product_formats.create(data) unless debug
          end
          puts "  #{data.inspect}"
        end
      else
        puts "! Error: Product not found #{isbn}" if verbose
        next
      end
    end
    # Archiving the file after it's parsed
    Coverpage::Utils.parser_archive(path, :debug => debug, :verbose => verbose) if archive
  end
  
  desc "Import ebook format data (fields: default_isbn, isbn + other product format fields). Optional: debug, verbose, file, mac, archive."
  task :eisbns => :environment do
    ENV['format_id'] = Format::PDF_ID.to_s
    Rake::Task['import:isbns'].invoke
  end

  desc "Import trade format data (fields: default_isbn, isbn + other product format fields). Optional: debug, verbose, file, mac, archive."
  task :tisbns => :environment do
    ENV['format_id'] = Format::TRADE_ID.to_s
    Rake::Task['import:isbns'].invoke
  end

  desc "Import replacements data exported from fmp (fields: ProdIDMaster, ProdIDRedirect). Options: debug, verbose, force, file, mac, archive."
  task :cw_replacements => :environment do
    file = ENV['file'].blank? ? 'replacements.csv' : ENV['file']
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    force = Coverpage::Utils.str_to_boolean(ENV['force'], :default => false)
    mac = Coverpage::Utils.str_to_boolean(ENV['mac'], :default => false)
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    Coverpage::Utils.print_variable(%w(debug verbose force file mac archive), binding)
    # FIELDS: ProdIDMaster, ProdIDRedirect
    path = Rails.root.join('tmp', 'import', file)
    test = FasterCSV.open(path, :row_sep => (mac ? "\r" : "\n"), :headers => true, :skip_blanks => true, :header_converters => :symbol).each do |row|
      unless old_product = Product.find_by_proprietary_id(row[:prodidmaster])
        puts "! Error: Old product not found '#{row[:prodidmaster]}'"
        next
      end
      unless new_product = Product.find_by_proprietary_id(row[:prodidredirect])
        puts "! Error: Replacement product not found '#{row[:prodidredirect]}'"
        next
      end
      old_product.replace_with(new_product, :debug => debug, :verbose => verbose, :force => force)
    end
    # Archiving the file after it's parsed
    Coverpage::Utils.parser_archive(path, :debug => debug, :verbose => verbose) if archive
  end

  desc "Import similarities data derived from Numbers.app file (fields: isbn1, isbn2). Options: debug, verbose, file, mac, archive."
  task :similarities => :environment do
    import_csv_file(:default => 'similarities.csv') do |row, debug, verbose, force|
      unless product1 = Product.find_by_isbn(row[:isbn1])
        puts "! Error: Product 1 not found '#{row[:isbn1]}'"
        next
      end
      unless product2 = Product.find_by_isbn(row[:isbn2])
        puts "! Error: Product 2 not found '#{row[:isbn2]}'"
        next
      end
      product1.similar_to(product2, :debug => debug, :verbose => verbose)
    end
  end

  def import_csv_file(options = {}, &block)
    raise ArgumentError unless block_given?
    file = ENV['file'].blank? ? options[:default] : ENV['file']
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    force = Coverpage::Utils.str_to_boolean(ENV['force'], :default => false)
    mac = Coverpage::Utils.str_to_boolean(ENV['mac'], :default => false)
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    Coverpage::Utils.print_variable(%w(debug verbose force file mac archive), binding)
    # FIELDS: isbn1, isbn2
    path = Rails.root.join('tmp', 'import', file)
    test = FasterCSV.open(path, :row_sep => (mac ? "\r" : "\n"), :headers => true, :skip_blanks => true, :header_converters => :symbol).each do |row|
      yield row.to_hash, debug, verbose, force
    end
    # Archiving the file after it's parsed
    Coverpage::Utils.parser_archive(path, :debug => debug, :verbose => verbose) if archive
  end

  desc "Restore the latest version of an archived file (tmp/import/archive/ -> tmp/import/). Required: file. Optional: debug, verbose, force."
  task :restore => :environment do
    file = Coverpage::Utils.impose_requirement(ENV, 'file')
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    force = Coverpage::Utils.str_to_boolean(ENV['force'], :default => false)
    Coverpage::Utils.print_variable(%w(debug verbose force file), binding)
    source_dir = Rails.root.join("tmp/import/archive")
    target_dir = Rails.root.join("tmp/import")
    ext = File.extname(file)
    basename = File.basename(file, ext)
    files = Dir.glob(File.join(source_dir, "#{basename}-*#{ext}"))
    Coverpage::Utils.print_variable(%w(basename ext files), binding) if debug
    unless files.any?
      FEEDBACK.error("No archives matching '#{file}'")
      exit(1)
    end
    source = files.last
    ext = File.extname(source) if ext.blank?
    target = File.join(target_dir, "#{basename}#{ext}")
    if File.exist?(target) && !force
      FEEDBACK.warning("File exists '#{target}'. Try option 'force'.")
      exit(0)
    end
    FileUtils.mv(source, target, :noop => debug, :verbose => verbose, :force => force)
  end
end

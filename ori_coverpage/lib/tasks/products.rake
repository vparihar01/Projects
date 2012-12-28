namespace :products do

  desc "Ensure default format exists for all products. Options: debug, verbose."
  task :default_format => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    Coverpage::Utils.print_variable(%w(debug verbose), binding)
    default_format = Format.find(Format::DEFAULT_ID)
    Product.all.each do |p|
      unless p.default_format
        puts "Creating #{default_format.name} for '#{p.name}' (#{p.id})..." if verbose
        unless debug
          if default_format.requires_valid_isbn
            puts "  Skip: Format requires valid isbn"
          else
            p.create_default_format(:format_id => Format::DEFAULT_ID)
            puts "  #{p.default_format.price} / #{p.default_format.price_list} (#{p.default_format.isbn})" if verbose
          end
        end
      end
    end
  end
  
  desc "Ensure pdf format exists for all product_downloads. Set pdf prices. Options: debug, verbose."
  task :pdf_format => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    Coverpage::Utils.print_variable(%w(debug verbose), binding)
    pdf_format = Format.find(Format::PDF_ID)
    default_format = Format.find(Format::DEFAULT_ID)
    ProductDownload.all.each do |pd|
      p = pd.title
      unless p.pdf_format
        puts "Creating #{pdf_format.name} for '#{p.name}' (#{p.id})..." if verbose
        unless debug
          if pdf_format.requires_valid_isbn
            puts "  Skip: Format requires valid isbn"
          else
            unless p.default_format
              puts "  Creating #{default_format.name} for '#{p.name}' (#{p.id})..." if verbose
              p.create_default_format(:format_id => Format::DEFAULT_ID)
            end
            p.create_pdf_format(:format_id => Format::PDF_ID, :dimensions => p.default_format.dimensions)
            puts "  #{p.pdf_format.price} / #{p.pdf_format.price_list} (#{p.pdf_format.isbn})" if verbose
          end
        end
      end
    end
  end
  
  desc "Check price changes vs actual. Required: state, price_field. Optional: verbose."
  task :check_price_changes => :environment do
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false)
    state = Coverpage::Utils.str_to_choice(ENV['state'], %w(new distributed undistributed implemented unimplemented), :allow_nil => false)
    price_field = Coverpage::Utils.str_to_choice(ENV['price_field'], ProductFormat::PRICE_FIELDS, :allow_nil => false)
    Coverpage::Utils.print_variable(%w(verbose state price_field), binding)
    if /^un/.match(state)
      price_changes = PriceChange.send(state)
    else
      price_changes = PriceChange.where(:state => state)
    end
    puts "#{price_changes.count} price changes found with state '#{state}'"
    exit 1 if price_changes.count == 0
    not_implemented = price_changes.all.select {|pc| pc.send(price_field) != pc.product_format.send(price_field)}
    header = ['id', 'name', 'format', "price_change.#{price_field}", "product_format.#{price_field}"]
    if not_implemented.any?
      puts "#{not_implemented.count} do not equal actual price"
      puts header.join(", ")
      not_implemented.each_with_index do |pc, i|
        pf = pc.product_format
        row = [i+1, "#{pf.try(:product).try(:name)} (#{pf.id})", pf.to_s, pc.send(price_field), pf.send(price_field)]
        puts row.join(", ")
      end
    else
      puts "All equal actual price"
    end
  end

  desc "Check list price calculation vs. list price actual of Titles. Command line parameters: 'verbose=[true|FALSE]'"
  task :check_list_prices => :environment do
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false)
    ProductFormat.includes(:product).where('product_formats.format_id = ? AND products.type = "Title"', Format::DEFAULT_ID).all.each do |pf|
      calc = (pf.price / CONFIG[:member_price_decimal]).round(2)
      calc2 = Integer((pf.price / CONFIG[:member_price_decimal]) * 100) / Float(100)
      if calc == pf.price_list
        puts "#{pf.product.name} (#{pf.product.id}): #{pf.price_list} = #{calc}" if verbose
      else
        puts "#{pf.product.name} (#{pf.product.id}): #{pf.price_list} != #{calc} != #{calc2}"
      end
    end
  end
  
  desc "Update list prices of Titles. Command line parameters: 'verbose=[true|FALSE]'"
  task :update_list_prices => :environment do
    unless CONFIG[:calculate_list_price] == true
      puts "Aborting: CONFIG[:calculate_list_price] is set to false"
      exit 0
    end
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false)
    ProductFormat.includes(:product).where('format_id = ? AND products.type = "Title"', Format::DEFAULT_ID).all.each do |pf|
      before = pf.price_list
      pf.calculate_list_price
      after = pf.price_list
      puts "#{pf.product.name} (#{pf.id}): #{before} -> #{after}" if verbose
      pf.save
    end
  end
  
  desc "Update ebook prices of Titles. Command line parameters: 'verbose=[true|FALSE]'"
  task :update_ebook_prices => :environment do
    unless CONFIG[:calculate_ebook_price] == true
      puts "Aborting: CONFIG[:calculate_ebook_price] is set to false"
      exit 0
    end
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false)
    ProductFormat.includes(:product).where('format_id = ? AND products.type = "Title"', Format::PDF_ID).all.each do |pf|
      before = pf.price
      pf.calculate_ebook_price(true)
      after = pf.price
      puts "#{pf.product.name} (#{pf.id}): #{before} -> #{after}" if verbose
      pf.save
    end
  end
  
  desc "Calculate ebook prices of Titles where price is currently zero. Command line parameters: 'verbose=[true|FALSE]'"
  task :calculate_ebook_prices => :environment do
    unless CONFIG[:calculate_ebook_price] == true
      puts "Aborting: CONFIG[:calculate_ebook_price] is set to false"
      exit 0
    end
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false)
    ProductFormat.includes(:product).where('format_id = ? AND products.type = "Title" AND price = 0', Format::PDF_ID).all.each do |pf|
      before = pf.price
      pf.calculate_ebook_price(true)
      after = pf.price
      puts "#{pf.product.name} (#{pf.id}): #{before} -> #{after}" if verbose
      pf.save
    end
  end
  
  desc "Change status of all products of a specified format. Command line parameters: 'format_id=[1|2|3]', 'status=[ACT|NYO|OP|...]', 'verbose=[true|FALSE]'."
  task :change_status => :environment do
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false)
    format_id = ENV['format_id'].to_i
    status = ENV['status']
    format_ids = Format.find_single_units.map(&:id)
    if !format_ids.include?(format_id)
      puts "format_id must be equal to #{format_ids.to_sentence(:last_word_connector => ' or ')}"
      exit
    end
    if !APP_STATUSES.keys.include?(status)
      puts "status must be equal to #{APP_STATUSES.keys.to_sentence(:last_word_connector => ' or ')}"
      exit
    end
    sql = "UPDATE product_formats SET status = '#{status}' WHERE format_id = '#{format_id}'"
    puts sql if verbose
    rows = ActiveRecord::Base.connection.update(sql)
    puts "  #{rows} row(s) affected..." if verbose
  end
  
  desc "Activate NYP product formats if available_on date has passed or is equal to a date specified (NYP -> ACT). Optional: debug, verbose, force, format_id, available_on."
  task :activate => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['debug'], :default => true) )
    force = Coverpage::Utils.str_to_boolean(ENV['force'], :default => false)
    format_id = Coverpage::Utils.str_to_choice(ENV['format_id'], Format.find_single_units.map(&:id), :allow_nil => true)
    available_on = ENV['available_on'].blank? ? Date.today : Date.parse(ENV['available_on'])
    Coverpage::Utils.print_variable(%w(debug verbose force format_id available_on), binding) if verbose
    if available_on > Date.today && !force
      FEEDBACK.error("Date must be prior to today. Try option 'force'.")
      exit(1)
    end
    product_formats = ProductFormat.includes(:product).where("product_formats.status = ?", "NYP").where("products.available_on <= ?", available_on)
    product_formats = product_formats.where("product_formats.format_id = ?", format_id) unless format_id.blank?
    product_formats.each do |product_format|
      FEEDBACK.verbose("Activating '#{product_format.product.name}' #{product_format} (#{product_format.id})...") if verbose
      product_format.update_attribute(:status, ProductFormat::ACTIVE_STATUS_CODE) unless debug
    end
  end
  
  desc "List isbn to eisbn"
  task :isbn_to_eisbn => :environment do
    puts "id  isbn  eisbn"
    Title.all.each do |t|
      puts "#{t.id}  #{t.isbn}  #{t.eisbn}"
    end
  end
  
  desc "List isbn to tisbn"
  task :isbn_to_tisbn => :environment do
    puts "id  isbn  tisbn"
    Title.all.each do |t|
      puts "#{t.id}  #{t.isbn}  #{t.trade_format.try(:isbn)}"
    end
  end
  
  desc "List products missing eisbn."
  task :missing_eisbn => :environment do
    Product.all.each do |p|
      Coverpage::Utils.print_product(p) unless p.eisbn
    end
  end
  
  desc "List titles with no associated product_download. Pass 'archive' option to determine if download exists as file. Optional: archive."
  task :missing_download => [:environment] do
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false)
    archive = ENV['archive'].to_s
    Coverpage::Utils.print_variable(%w(verbose archive), binding) if verbose
    titles = Title.includes(:product_formats, :download).where("product_downloads.id IS NULL and product_formats.format_id = ?", Format::DEFAULT_ID).order('product_formats.isbn').all
    puts "\nMissing download (#{titles.count} titles):"
    Coverpage::Utils.print_products(titles, :by => :isbn)
    if File.directory?(archive)
      result = {:exists => [], :doesnotexist => []}
      titles.each_with_index do |t, i|
        ebook = File.join(archive, "#{t.isbn}.pdf")
        if File.exist?(ebook)
          result[:exists] << t
        else
          result[:doesnotexist] << t
        end
      end
      unless result[:exists].size == 0 && result[:doesnotexist].size == titles.count
        puts "File exists -> Create product_download (#{result[:exists].size} titles):"
        Coverpage::Utils.print_products(result[:exists], :by => :isbn)
        puts "\nFile missing (#{result[:doesnotexist].size} titles):"
        Coverpage::Utils.print_products(result[:doesnotexist], :by => :isbn)
      else
        puts "\nAll files missing"
      end
    end
  end

  desc "List products without Bisac. Command line parameters: 'verbose=[true|FALSE]'."
  task :missing_bisac => :environment do
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false)
    Coverpage::Utils.print_variable(%w(verbose), binding) if verbose
    Product.all.each_with_index do |product, i|
      msg = "#{sprintf('%4s', i+1)}. #{product.name} (#{product.isbn}) | #{product.id} | #{product.available_on}"
      if product.bisac_subjects.any?
        if verbose
          msg += "\n  #{product.bisac_subjects.map(&:code).join(', ')}"
        else
          msg = nil
        end
      else
        msg += "\n  No Bisac found" if verbose
      end
      puts msg unless msg.blank?
    end
  end
  
  desc "Update product download title_id. Useful when association is broken (ie, products are deleted and downloads aren't). Options: debug, verbose."
  task :fix_download => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    Coverpage::Utils.print_variable(%w(debug verbose), binding) if verbose
    ProductDownload.callback_switch = false
    Excerpt.callback_switch = false
    ProductDownload.all.each do |pd|
      isbn = File.basename(pd.filename, ".pdf")
      print "Download '#{pd.public_filename.sub(Rails.root.join("protected/ebooks/"), '')}': #{isbn} -> " if verbose
      if product = Title.find_by_isbn(isbn)
        puts "#{product.name} (#{product.id})" if verbose
        if pd.exist?
          if excerpt = Excerpt.find_by_title_id(pd.title_id)
            print "  Updating excerpt '#{excerpt.id}' (#{excerpt.title_id} -> #{product.id})... " if verbose
            begin
              excerpt.update_attribute(:title_id, product.id) unless debug
              puts "OK"
            rescue
              puts "FAILED!" if verbose
              nil
            end
          else
            puts "  ! Warning: Excerpt not found" if verbose
          end
          print "  Updating product_download '#{pd.id}' (#{pd.title_id} -> #{product.id})... " if verbose
          begin
            pd.update_attribute(:title_id, product.id) unless debug
            puts "OK"
          rescue
            puts "FAILED!" if verbose
            nil
          end
        else
          puts "  ! Error: Download file does not exist." if verbose
        end
      else
        puts "TITLE NOT FOUND!" if verbose
      end
    end
  end
  
  desc "Update specified products (by isbn or season), setting certain field to a certain value. Required: season/isbns, field, value. Optional: debug, verbose."
  task :update => :environment do
    attributes_allowed = Product.new.attributes.keys.map{|k| k.to_sym}
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    field = Coverpage::Utils.str_to_choice(ENV['field'], attributes_allowed, :allow_nil => false)
    value = ENV['value']
    if ENV['isbns'].blank?
      start_date, end_date = Coverpage::Utils.options_to_dates(ENV)
    else
      isbns = (ENV['isbns'] || "").split(',').map{|i| i.strip}
    end
    Coverpage::Utils.print_variable(%w(debug verbose isbns field value), binding)
    products = Product.find_using_options(:product_select => (isbns.any? ? "by_isbn" : "by_date"), :start_date => start_date, :end_date => end_date, :isbns => isbns)
    products.each do |product|
      FEEDBACK.print_record(product) if verbose
      product.update_attribute(field, value) unless debug
    end
  end

  desc "Verify product format is associated with correct product. Find product format by isbn. File must be in 'tmp/import'. Optional: debug, verbose, file, mac, archive, isbns."
  task :verify_formats => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    mac = Coverpage::Utils.str_to_boolean(ENV['mac'], :default => false)
    file = ENV['file'].blank? ? 'product_formats.csv' : ENV['file']
    isbns = (ENV['isbns'].blank? ? [] : ENV['isbns'].split(',').map{|i| i.strip})
    Coverpage::Utils.print_variable(%w(debug verbose file mac archive isbns), binding)
    path = Rails.root.join('tmp/import', file)
    FasterCSV.read(path, :row_sep => (mac ? "\r" : "\n"), :headers => true, :skip_blanks => true, :header_converters => :symbol).each do |row|
      next if isbns.any? && !isbns.include?(row.to_hash[:isbn])
      FEEDBACK.debug("row = #{row.to_hash.inspect}") if debug
      data = CsvParser.convert_row_to_data(row.to_hash)
      FEEDBACK.debug("data = #{data.inspect}") if debug
      if record = ProductFormat.find_by_isbn(data[:isbn])
        if record.product.proprietary_id == row.to_hash[:proprietary_product_id]
          FEEDBACK.verbose("#{data[:isbn]} | #{record.to_s} | #{record.product.proprietary_id} (OK)") if verbose
        else
          FEEDBACK.error("#{data[:isbn]} | #{record.to_s} | #{record.product.available_on} | #{record.product.proprietary_id} (Wrong) | #{row.to_hash[:proprietary_product_id]} (Expected)")
        end
      else
        FEEDBACK.error("Product format not found isbn '#{data[:isbn]}'")
      end
    end
    Coverpage::Utils.parser_archive(path, :debug => debug, :verbose => verbose) if archive
  end

end

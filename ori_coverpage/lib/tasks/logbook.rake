namespace :logbook do
  
  desc "Verify ISBN logbook. If errors found, add columns to help solve. Default source file is 'CL-logbook_978160279' (source=CL-logbook_978160279). Default target file is 'logbook' (target=logbook). Files must have csv extension. Files must be in 'tmp' directory. Interactive option (interactive=true)."
  task :verify => :environment do
    # process command line parameters
    verbose = ENV['verbose'].blank? ? false : !/true/i.match(ENV['verbose']).nil?
    interactive = ENV['interactive'].blank? ? false : !/true/i.match(ENV['interactive']).nil?
    source = ENV['source'].blank? ? 'CL-logbook_978160279' : ENV['source']
    target = ENV['target'].blank? ? "#{source}-REV" : ENV['target']
    dir = 'tmp'
    ext = 'csv'
    
    source = source.gsub(/[.\/ ]/, "_").untaint
    target = target.gsub(/[.\/ ]/, "_").untaint
    source_path = Rails.root.join(dir, "#{source}.#{ext}")
    target_path = Rails.root.join(dir, "#{target}.#{ext}")
    
    if verbose
      puts "source = #{source_path}"
      puts "target = #{target_path}"
    end
    
    # Bindings to format_ids
    binding_formats = {'Library Binding' => Format::DEFAULT_ID, 'E-Book' => Format::PDF_ID, 'Trade Paper' => Format::TRADE_ID, }
    active_status = "AC (USA)"
    withdrawn_status = "WI (USA)"
    statuses = [active_status, withdrawn_status].map{|x| Regexp.escape(x)}.join('|')
    
    # Parse source
    puts "Verifying ISBN logbook '#{source}'..." if verbose
    out = []
    status_rows = []
    withdrawn_rows = []
    binding_rows = []
    ok_rows = []
    name_rows = []
    dupe_name_rows = []
    dupe_format_rows = []
    product_rows = []
    format_rows = []
    prev_collection = nil
    error = false
    ProductsParser::parse_file(source_path) do |row|
      # row headings are turned into symbols, lowercase
      # Fix data
      row[:xisbn] = row[:isbn13].gsub(/-/,'')
      if row[:title].blank?
        row[:xtype] = ''
        row[:xcollection] = ''
        row[:xmsg] = ''
      else
        row_to_s = "#{row[:isbn13]} | #{row[:title]} | #{row[:binding]} "
        if !/#{statuses}/.match(row[:status])
          # Unsupported status
          row[:xtype] = ''
          row[:xcollection] = ''
          row[:xmsg] = 'Unsupported status'
          status_rows << row_to_s
          error = true
        elsif /#{Regexp.escape(withdrawn_status)}/.match(row[:status])
          # TODO: if ISBN withdrawn -> set product format status to WD
          row[:xtype] = ''
          row[:xcollection] = ''
          row[:xmsg] = 'Must set product format status to WD'
          withdrawn_rows << row_to_s
        elsif !binding_formats.keys.include?(row[:binding])
          # Unsupported binding
          row[:xtype] = ''
          row[:xcollection] = ''
          row[:xmsg] = 'Unsupported binding'
          binding_rows << row_to_s
          error = true
        elsif product = Product.find_by_isbn_and_name(row[:xisbn], row[:title])
          # ISBN found, Product name found: All's good
          row[:xtype] = product.type
          row[:xcollection] = product.collection ? product.collection.name : ''
          row[:xmsg] = ''
          ok_rows << row_to_s
        elsif product = Product.find_by_isbn(row[:xisbn])
          # ISBN found, Name Mismatch
          row[:xtype] = product.type
          row[:xcollection] = product.collection ? product.collection.name : ''
          row[:xmsg] = "Name mismatch: #{row[:title]}"
          row[:title] = product.name # Fixing name mismatch
          name_rows << "#{row_to_s}\n  #{product.name}"
          error = true
        else
          products = Product.where("name = ?", row[:title]).all
          if products.size == 0
            # ISBN not found, Product name not found: 
            #   Option 1: Row name was misspelled. ISBN should be added to an existing product.
            #   Option 2: Product does not exist. Create product and product_format record.
            row[:xtype] = ''
            row[:xcollection] = ''
            row[:xmsg] = 'Name not found'
            product_rows << row_to_s
            error = true
          elsif products.size == 1
            # ISBN not found, Product name found: 
            #   Create product_format record
            product = products[0]
            row[:xtype] = product.type
            row[:xcollection] = product.collection ? product.collection.name : ''
            if pf = product.product_formats.find_by_format_id(binding_formats[row[:binding]])
              row[:xmsg] = "#{pf.to_s} already exists (#{pf.isbn})"
              dupe_format_rows << "#{row_to_s}\n  #{row[:xmsg]}"
              error = true
            else
              row[:xmsg] = 'ISBN not found'
              format_rows << row_to_s
            end
          else
            # Multiple products found:
            #   Option 1: Choose one then create product_format record
            #   Option 2: Create product and product_format record
            names = products.map(&:name_for_dropdown)
            collection = products.inject([]){|sum, p| sum << (p.collection ? p.collection.name : nil)}.compact
            # First check logbook for solution using xcollection
            if !row[:xcollection].blank? && product = Title.includes(:collection).where("products.name = ? AND collections.name = ?", row[:title], row[:xcollection]).first
              format_rows << row_to_s
            else
              dupe_name_rows << "#{row_to_s}\n  " + names.join("\n  ")
              error = true
            end
            row[:xtype] = ''
            row[:xcollection] = collection.include?(prev_collection) ? prev_collection : nil
            row[:xmsg] = "Multiple names found: #{names.join(' | ')}"
          end
        end
        prev_collection = row[:xcollection]
      end
      out << row
    end
    # Output results
    if verbose
      [
        {:rows => status_rows, :msg => "Unsupported Status"}, 
        {:rows => withdrawn_rows, :msg => "ISBN Withdrawn -- update product"}, 
        {:rows => binding_rows, :msg => "Unsupported Binding"}, 
        {:rows => name_rows, :msg => "ISBN Found, Names Mismatch"}, 
        {:rows => dupe_name_rows, :msg => "ISBN Not Found, Duplicate Names"}, 
        {:rows => dupe_format_rows, :msg => "ISBN Not Found, Name Found, Duplicate Formats"}, 
        {:rows => product_rows, :msg => "ISBN Not Found, Name Not Found"}, 
        # {:rows => format_rows, :msg => "ISBN Not Found, Name Found"}, 
        # {:rows => ok_rows, :msg => "ISBN Found, Name Found"}, 
      ].each do |data|
        if data[:rows].size > 0
          msg = "#{data[:msg]} (#{data[:rows].size})"
          puts "\n#{msg}\n#{msg.gsub(/./, '-')}"
          data[:rows].each {|row| puts row}
        end
      end
    end
    # Process if no errors
    if error == true
      # Write new logbook file
      puts "\nErrors found..." if verbose
      puts "Write to '#{target}'? [yN]"
      write = STDIN.gets
      write = write.blank? ? false : !/y/i.match(write).nil?
      if !interactive || write
        puts "Writing new logbook '#{target}'..." if verbose
        FasterCSV.open(target_path, "w", {:row_sep => "\n", :force_quotes => true}) do |csv|
          csv << %w(ISBN13 ISBN TITLE BINDING STATUS xisbn xtype xcollection xmsg)
          out.each do |x|
            csv << [x[:isbn13], x[:isbn], x[:title], x[:binding], x[:status], x[:xisbn], x[:xtype], x[:xcollection], x[:xmsg]]
          end 
        end
        puts "Created '#{target_path}'"
      end
    else
      puts "No errors found..." if verbose
      if interactive == true
        task = "logbook:process"
        puts "Run rake #{task}? [yN]"
        run = STDIN.gets
        run = run.blank? ? false : !/y/i.match(run).nil?
        Rake::Task[task].invoke if run # ENV passed automatically
      end
    end
  end
  
  desc "Process ISBN logbook. Default source file is 'logbook' (source=logbook). Files must have csv extension. File must be in 'tmp' directory."
  task :process => [:environment, :verify] do
    # process command line parameters
    verbose = ENV['verbose'].blank? ? false : !/true/i.match(ENV['verbose']).nil?
    source = ENV['source'].blank? ? 'logbook' : ENV['source']
    dir = 'tmp'
    ext = 'csv'
    
    source = source.gsub(/[.\/ ]/, "_").untaint
    source_path = Rails.root.join(dir, "#{source}.#{ext}")
    
    if verbose
      puts "source = #{source_path}"
    end
    
    # Bindings to format_ids
    binding_formats = {'Library Binding' => Format::DEFAULT_ID, 'E-Book' => Format::PDF_ID, 'Trade Paper' => Format::TRADE_ID, }
    statuses = ["AC (USA)"].map{|x| Regexp.escape(x)}.join('|')
    
    # Parse source
    puts "Processing ISBN logbook '#{source}'..." if verbose
    ProductsParser::parse_file(source_path) do |row|
      row_to_s = "#{row[:isbn13]} | #{row[:title]} | #{row[:binding]} "
      isbn = row[:xisbn]
      name = row[:title]
      collection = row[:xcollection]
      if !name.blank? && /#{statuses}/.match(row[:status]) && product = ( (!row[:xcollection].blank? && Title.includes(:collection).where("products.name = ? AND collections.name = ?", name, collection).first) || Product.where("products.name = ?", name).first )
        isbns = product.product_formats.map(&:isbn)
        unless isbns.include?(isbn)
          format_id = binding_formats[row[:binding]]
          data = {:format_id => format_id, :isbn => isbn}
          puts "Creating #{Format.find(format_id).name} for '#{product.name}'..."
          pf = product.product_formats.create(data)
          if pf.errors.any?
            puts "  #{pf.errors.full_messages}"
          end
        end
      end
    end
    
  end
  
end

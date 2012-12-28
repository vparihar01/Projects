module ProductsParser
  require 'fastercsv'
  
  def self.log(msg)
    # puts "# #{msg} "
    Rails.logger.debug "# #{msg} "
  end
  
  def self.execute(path, *args)
    options = args.extract_options!.symbolize_keys
    i = 0
    parse_file(path, options[:mac]) do |row|
      parse_row(row) do |product_data, subjects, bisacs, product_formats, contributors, assemblies|
        if !product_formats.detect {|pf| !pf[:isbn].blank?}
          log("Warning: isbns not defined '#{product_data[:name]}' (SKIP)")
        else
          i += 1
          klass = (product_data.delete(:type) || 'product').classify.constantize
          pf = nil
          product_formats.detect {|product_format| pf = ProductFormat.find_by_isbn(product_format[:isbn])}
          if pf
            unless product = pf.product
              log("Warning: orphaned product_format, product_id = '#{pf.product_id}', isbn = '#{pf.isbn}' (SKIP)")
              next
            end
            product.update_attributes(product_data)
          else
            log("Creating new product '#{product_data[:name]}' (klass: #{klass})")
            # product_data.each { |k,v| log("'#{k}' => '#{v}'") } # extended logging
            product = klass.create(product_data)
          end
          product_formats.each do |data|
            unless data[:isbn].nil?
              pf = product.product_formats.find_by_format_id(data[:format_id])
              if pf
                pf.update_attributes(data)
              else
                product.product_formats.create(data)
              end
            end
          end
          # process subjects for set only
          if product.is_a?(Assembly)
            log("DEBUG: deleting previous subject assignments for product '#{product.id}'")
            rows = ActiveRecord::Base.connection.delete("DELETE FROM categories_products WHERE product_id = '#{product.id}'")
            log("DEBUG: '#{rows}' row(s) deleted")
            subjects.each do |name|
              s = Category.find_or_create_by_name(name)
              s.products << product unless s.products.map(&:id).include?(product.id)
            end
            dupe_assembly_titles(product.name) # dupe titles from old assembly to new assembly
          end # process subjects
          # process bisacs
          bisacs.each do |code|
            if bs = BisacSubject.find_by_code(code)
              ba_data = {:product_id => product.id, :bisac_subject_id => bs.id}
              ba = BisacAssignment.find_or_create_by_product_id_and_bisac_subject_id(ba_data)
              log(ba.errors.full_messages) if ba.errors.any?
            else
              log("Warning: unknown bisac code '#{code}'")
            end
          end # process bisacs
          # process contributors
          contributors.each do |c|
            product.set_contributor_role(c[:name], c[:role])
          end # process contributors
          # process assemblies
          assemblies.each do |name|
            if assembly_id = get_assembly_id_by_name(name)
              aa_data = {:product_id => product.id, :assembly_id => assembly_id}
              aa = AssemblyAssignment.find_or_create_by_product_id_and_assembly_id(aa_data)
              log(aa.errors.full_messages) if aa.errors.any?
            end
          end # process assemblies
        end # if isbn
      end # parse row
    end # parse file
    if i == 0
      log("! Error: No records imported. Check file.")
      raise unless options[:debug]
    end
    # Archiving the file after it's parsed
    if options[:archive]
      log("Archiving '#{File.basename(path)}' to '#{CONFIG[:parser_archive_dir]}'...") if options[:verbose]
      unless options[:debug]
        dir = Rails.root.join(CONFIG[:parser_archive_dir])
        FileUtils.mkdir_p(dir)
        FileUtils.mv(path, "#{dir}/products-#{Time.now.strftime('%Y%m%d%H%M')}.csv")
      end
    end
  end
  
  def self.parse_file(file, mac=false)
    # log("parse_file: #{file}")
    FasterCSV.read(file, 
      :row_sep => (mac ? "\r" : "\n"), 
      :headers => true, 
      :skip_blanks => true, 
      :header_converters => :symbol).each { |row| yield row.to_hash }
  rescue Errno::ENOENT
    log("parse_file -- file not found: #{file}")
    return Array.new
  end
  
  def self.parse_row(row)
    log("parse_row: #{row.inspect}")
    # convert bad data
    row = convert(row, [:type], {"series" => "Assembly", "subseries" => "Assembly", "set" => "Assembly", "subset" => "Assembly"})
    row = convert(row, [:interest_level_min, :interest_level_max, :reading_level], Level.all.inject({}){|h,e| h[e.abbreviation] = e.id; h})
    row = convert(row, [:has_index, :has_bibliography, :has_glossary, :has_sidebar, :has_table_of_contents, :has_author_biography, :has_map, :has_timeline], {"YES" => true, "NO" => false})
    row[:author] = nil if row[:author] && row[:author].downcase == 'various'
    
    # Rename columns
    rename = {:interest_level_min => :interest_level_min_id, :interest_level_max => :interest_level_max_id, :reading_level => :reading_level_id}
    rename.each do |old_key, new_key|
      row[new_key] = row.delete(old_key)
    end
    
    non_product_fields = %w(series subseries set subset set1 set2 set3 price price_list subject1 subject2 illustrator bisacs isbn pdf_isbn trade_isbn hosted_isbn binding_type dimensions weight status proprietary_collection_id)
    product = row.reject{|k,v| v.blank? || non_product_fields.include?(k.to_s)}
    if product[:type] == 'Title'
      product[:is_book] = product[:is_taxable] = true
    elsif product[:type] == 'Assembly'
      product[:is_book] = false
      product[:is_taxable] = true
      # Create collection matching current product (ie, assembly) name 
      # if series is not specified and it doesn't already exist
      # if row[:series].blank? && !Collection.find_by_name(row[:name])
        # data = {:name => row[:name], :released_on => row[:available_on], :description => row[:description]}
        # assembly_collection = Collection.create(data)
      # end
    end

    # process collections
    if !row[:proprietary_collection_id].blank?
      # important: collections must be imported prior to products
      if collection = Collection.find_by_proprietary_id(row[:proprietary_collection_id])
        product[:collection_id] = collection.id
      else
        log("! Error: Collection not found '#{row[:proprietary_collection_id]}'. Must import collections prior to products.")
      end
    elsif !row[:series].blank?
      # create collections if they don't exist
      if parent_collection = Collection.find_or_create_by_name(row[:series])
        product[:collection_id] = parent_collection.id
        # product belongs to subcollection, if it exists
        unless row[:subseries].blank?
          if child_collection = Collection.find_or_create_by_name(row[:subseries])
            product[:collection_id] = child_collection.id
            child_collection.update_attribute(:parent_id, parent_collection.id)
          end
        end
      end
    end # process collections

    subjects = []
    subjects << row[:subject1] unless row[:subject1].blank?
    subjects << row[:subject2] unless row[:subject2].blank?
    bisacs = row[:bisacs].blank? ? [] : row[:bisacs].gsub(/\s/,"").split(",")
    assemblies = []
    assemblies << row[:set1] unless row[:set1].blank?
    assemblies << row[:set2] unless row[:set2].blank?
    assemblies << row[:set3] unless row[:set3].blank?
    
    contributors = []
    contributors << {:name => row[:author], :role => 'Author'} unless (row[:author].blank? || row[:author].downcase == 'various')
    contributors << {:name => row[:illustrator], :role => 'Illustrator'} unless (row[:illustrator].blank? || row[:illustrator].downcase == 'various')
    
    product_formats = [{}]
    product_formats[0][:format_id] = Format::DEFAULT_ID
    product_formats[0][:price_list] = row[:price_list] unless row[:price_list].blank?
    product_formats[0][:price] = row[:price] unless row[:price].blank?
    product_formats[0][:isbn] = row[:isbn] unless row[:isbn].blank?
    product_formats[0][:dimensions] = row[:dimensions] unless row[:dimensions].blank?
    product_formats[0][:weight] = row[:weight] unless row[:weight].blank?
    product_formats[0][:status] = row[:status] unless row[:status].blank?
    
    log("product: #{product.inspect}")
    log("product_formats: #{product_formats.inspect}")
    
    yield product, subjects, bisacs, product_formats, contributors, assemblies
  end
  
  def self.get_assembly_id_by_name(name)
    unless name.blank?
      # could be multiple assemblies with same name -- get latest
      assembly = Assembly.find_by_name(name, :order => 'available_on DESC')
      if assembly.nil?
        log("Warning: Assembly not found by name specified: #{name}. Verify spelling or create record.") unless name.empty?
        nil
      else
        assembly.id
      end
    end
  end
  
  def self.convert(row = [], columns = [], transforms = {})
    # make keys lowercase, so transform is case insensitive
    transforms = transforms.to_a.inject({}) {|h,e| h[e[0].downcase] = e[1]; h}
    columns.each {|x| row[x] = transforms[row[x].downcase] if row[x] && transforms.has_key?(row[x].downcase)}
    row
  end
  
  def self.dupe_assembly_titles(name)
    log("DEBUG: dupe_assembly_titles")
    assemblies = Assembly.where("name = ?", name).order('available_on DESC').limit(2)
    log("DEBUG: assemblies.size = #{assemblies.size}")
    return unless assemblies.size == 2
    source = assemblies[1]
    target = assemblies[0]
    # update assembly assignments
    log "Copying assembly assignments (#{source.id} => #{target.id})..."
    current_title_ids = target.titles.map(&:id)
    touched = false
    source.titles.each do |title|
      if current_title_ids.include?(title.id)
        log "  Skipping '#{title.name}' (#{title.id}) -- already assigned..."
      else
        log "  Adding '#{title.name}' (#{title.id})..."
        target.titles << title
        touched = true
      end
    end
    if touched
      log "  Calculating prices..."
      target.calculate_price
    end
  end
  
end

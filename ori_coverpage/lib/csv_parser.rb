module CsvParser
  require 'fastercsv'
  @@path = Rails.root.join('tmp', 'import')

  def self.path_to_file(file)
    File.join(@@path, file)
  end
  
  def self.execute(table, *args)
    options = args.extract_options!.symbolize_keys
    begin
      klass = table.classify.constantize
    rescue NameError => e
      class_error = true
      FEEDBACK.warning "Unacceptable class name '#{table.classify}'" if options[:verbose]
    end
    ext = 'csv'
    path = path_to_file("#{table}.#{ext}")
    basename = File.basename(path)
    unless File.exist?(path)
      FEEDBACK.error "File not found '#{path}'"
      raise Errno::ENOENT
    end
    table_method = "#{table}_row"
    custom = self.respond_to?(table_method)
    if options[:truncate]
      if class_error
        FEEDBACK.verbose "Truncating '#{table}' table..." if options[:verbose]
        ActiveRecord::Base.connection.execute("TRUNCATE #{table}") unless options[:debug]
      else
        FEEDBACK.verbose "Destroying all '#{klass}' records..." if options[:verbose]
        klass.destroy_all unless options[:debug]
      end
    end
    if options[:verbose]
      FEEDBACK.verbose "Parsing file '#{basename}'..."
      FEEDBACK.verbose "  Using custom row method..." if custom
    end
    i = 0
    parse_file(path, options[:mac]) do |row|
      i += 1
      FEEDBACK.important("#{sprintf('%4s', i)}. row = #{row.inspect}")
      if custom
        self.send(table_method, row, options)
      else
        props = row.to_hash.reject {|k, v| k.to_s == 'proprietary_id' || /^(?!proprietary_)/.match(k.to_s)}
        columns = props.keys.map {|k, v| k.to_s.gsub(/proprietary_(.*)/, '\1').to_sym}
        if data = convert_row_to_data(row, :required => columns)
          if class_error
            sql = "INSERT INTO #{table} (#{data.keys.map{|x| x.to_s}.join(', ')}) VALUES ('#{data.values.join("', '")}')"
            perform_sql_insert(sql, options)
          else
            if ! options[:truncate] && klass.column_names.include?('proprietary_id') && record = klass.find_by_proprietary_id(data[:proprietary_id])
              update_record(record, data, options)
            else
              create_record(klass, data, options)
            end
          end
        else
          FEEDBACK.error("Failed to convert row to data")
        end
      end
    end # parse file
    if i == 0
      FEEDBACK.error("No records imported. Check file.")
      raise unless options[:debug]
    end
    # Archiving the file after it's parsed
    if options[:archive]
      FEEDBACK.verbose "Archiving '#{basename}' to '#{CONFIG[:parser_archive_dir]}'..." if options[:verbose]
      unless options[:debug]
        dir = Rails.root.join(CONFIG[:parser_archive_dir])
        FileUtils.mkdir_p(dir)
        FileUtils.mv(path, "#{dir}/#{table}-#{Time.now.strftime('%Y%m%d%H%M')}.csv")
      end
    end
  end
  
  protected
  
  def self.parse_file(file, mac=false)
    FasterCSV.read(file, 
      :row_sep => (mac ? "\r" : "\n"), 
      :headers => true, 
      :skip_blanks => true, 
      :header_converters => :symbol).each { |row| yield row.to_hash }
  end
  
  def self.links_row(row, options = {})
    if Link.find_by_proprietary_id(row[:proprietary_id]) || Link.find_by_url(row[:url])
      FEEDBACK.verbose("Skip: Link already exists")
    else
      FEEDBACK.verbose("Creating link...")
      link = Link.new(row)
      link.save!
    end
  end
  
  def self.postal_codes_row(row, options = {})
    return false unless data = convert_row_to_data(row, :required => [:name], :exclude => [:zone_code])
    FEEDBACK.warning("Zone not found '#{row[:zone_code]}'") unless zone = Zone.find_by_code(row[:zone_code])
    data[:zone_id] = zone.try(:id)
    if record = PostalCode.find_by_name(data[:name])
      update_record(record, data, options)
    else
      create_record(PostalCode, data, options)
    end
  end
  
  def self.contracts_row(row, options = {})
    return false unless data = convert_row_to_data(row, :required => [:sales_team_id, :sales_zone_id])
    if record = Contract.find_by_sales_team_id_and_sales_zone_id_and_category(data[:sales_team_id], data[:sales_zone_id], data[:category])
      update_record(record, data, options)
    else
      create_record(Contract, data, options)
    end
  end

  def self.addresses_row(row, options = {})
    return false unless data = convert_row_to_data(row, :required => [:addressable_type], :exclude => [:postal_code_name, :proprietary_addressable_id, :type])
    (FEEDBACK.error("Postal code not found '#{row[:postal_code_name]}'") and return false) unless postal_code = PostalCode.find_by_name(row[:postal_code_name].gsub(/-.*/, ''))
    (FEEDBACK.error("Addressable type failed to instantiate '#{row[:addressable_type]}'") and return false) unless klass = row[:addressable_type].classify.constantize rescue nil
    (FEEDBACK.error("#{klass.to_s} not found '#{row[:proprietary_addressable_id]}'") and return false) unless record = klass.find_by_proprietary_id(row[:proprietary_addressable_id])
    data.merge!(:postal_code_id => postal_code.try(:id), :addressable_id => record.try(:id))
    if !data[:proprietary_id].blank? && record = Address.find_by_proprietary_id(data[:proprietary_id])
      update_record(record, data, options)
    else
      create_record(Address, data, options)
    end
  end
  
  def self.sales_teams_row(row, options = {})
    return false unless data = convert_row_to_data(row, :exclude => [:proprietary_user_id])
    FEEDBACK.warning("User not found '#{row[:proprietary_user_id]}'") unless user = User.find_by_proprietary_id(row[:proprietary_user_id])
    data.merge!(:managed_by => user.try(:id))
    if record = SalesTeam.find_by_proprietary_id(data[:proprietary_id])
      update_record(record, data, options)
    else
      create_record(SalesTeam, data, options)
    end
  end

  def self.sales_targets_row(row, options = {})
    return false unless data = convert_row_to_data(row, :required => [:sales_team_id])
    if record = SalesTarget.find_by_sales_team_id_and_year(data[:sales_team_id], data[:year])
      update_record(record, data, options)
    else
      create_record(SalesTarget, data, options)
    end
  end

  def self.price_changes_row(row, options = {})
    data = {}
    if row.has_key?(:product_format_id)
      data = row
    else
      # This corresponds to a TCW Filemaker file
      data[:price] = row[:priceslnext]
      data[:price_list] = row[:pricelistnext]
      (FEEDBACK.error("ProductFormat not found #{row[:isbntext]}") and return false) unless pf = ProductFormat.find_by_isbn(row[:isbntext])
      data[:product_format_id] = pf.id
    end
    data[:implement_on] ||= Product.upcoming_on
    (FEEDBACK.error("Price is blank #{data[:price]}") and return false) if data[:price].blank?
    (FEEDBACK.error("List Price is blank #{data[:price_list]}") and return false) if data[:price_list].blank? && CONFIG[:calculate_list_price] != true
    if record = PriceChange.find_new_price_change_by_product_format_id(data[:product_format_id])
      update_record(record, data, options)
    else
      create_record(PriceChange, data, options)
    end
  end

  def self.product_formats_row(row, options = {})
    return false unless data = convert_row_to_data(row, :required => [:product_id])
    # Ensure that prices are not null
    data[:price] = 0 if data[:price].blank?
    data[:price_list] = 0 if data[:price_list].blank?
    if record = ProductFormat.find_by_product_id_and_format_id(data[:product_id], data[:format_id])
      update_record(record, data, options)
    else
      create_record(ProductFormat, data, options)
    end
  end
  
  def self.collections_row(row, options = {})
    cid = row[:proprietary_id]
    pid = row[:proprietary_parent_id]
    FEEDBACK.warning("Parent Collection not found #{pid}") unless pid.blank? || parent = Collection.find_by_proprietary_id(pid)
    data = convert_row_to_data(row, :exclude => [:proprietary_parent_id])
    data.merge!(:parent_id => parent.id) if parent
    if record = Collection.find_by_proprietary_id(cid)
      update_record(record, data, options)
    else
      create_record(Collection, data, options)
    end
  end

  def self.sales_reps_row(row, options = {})
    return false unless data = convert_row_to_data(row, :required => [:sales_team_id, :email])
    if record = User.find_by_proprietary_id(data[:proprietary_id]) || record = User.find_by_email(data[:email])
      unless record.is_a?(SalesRep) || record.is_a?(Admin)
        FEEDBACK.verbose("Converting user to SalesRep...")
        record[:type] = 'SalesRep'
      end
      data.delete_if{|k,v| !%w(sales_team_id proprietary_id).include?(k.to_s)}
      update_record(record, data, options)
    else
      data.merge!(:password => 't3mporary', :password_confirmation => 't3mporary')
      create_record(SalesRep, data, options)
    end
  end

  # Utility methods
  
  def self.convert_row_to_data(row, options = {})
    return false unless related = transform_proprietary_ids(row, options)
    data = row.to_hash.reject{|k, v| (options[:exclude] && options[:exclude].include?(k)) || /^(proprietary_)\w+_id/.match(k.to_s)}
    data.merge!(related)
    options[:required].each do |k|
      if data[k].blank?
        FEEDBACK.error("#{k.to_s} is required")
        return false
      end
    end if options[:required]
    data
  end

  def self.transform_proprietary_ids(row, options = {})
    error = false
    records = {}
    props = row.to_hash.reject {|k, v| k.to_s == 'proprietary_id' || (options[:exclude] && options[:exclude].include?(k)) || /^(?!proprietary_)/.match(k.to_s)}
    props.each do |k, v|
      if label = k.to_s.gsub(/proprietary_(.*)/, '\1').to_sym
        if klass = label.to_s.gsub(/_id$/, '').classify.constantize
          unless record = klass.find_by_proprietary_id(v)
            if options[:required] && options[:required].include?(label)
              FEEDBACK.error("#{klass.to_s} not found '#{v}'")
              error = true
            elsif options[:optional] && options[:optional].include?(label)
              FEEDBACK.warning("#{klass.to_s} not found '#{v}'")
            end
          end
          records[label] = record.try(:id)
        end
      end
    end
    return false if error
    records
  end
  
  def self.update_record(record, data, options = {})
    FEEDBACK.verbose("Updating #{record.class.to_s} '#{data.inspect}'...")
    return if options[:debug]
    # record.update_attributes!(data) # This would be stricter
    unless record.update_attributes(data)
      FEEDBACK.error("Update failed")
      FEEDBACK.error(record.errors.inspect)
    end
  end
  
  def self.create_record(klass, data, options = {})
    FEEDBACK.verbose("Creating #{klass.to_s} '#{data.inspect}'...")
    return if options[:debug]
    # klass.create!(data) # This would be stricter
    record = klass.create(data)
    unless record.valid?
      FEEDBACK.error("Create failed")
      FEEDBACK.error(record.errors.inspect)
    end
  end
  
  def self.perform_sql_insert(sql, options)
    if options[:debug]
      FEEDBACK.verbose(sql)
    else
      ActiveRecord::Base.connection.insert(sql)
    end
  end
  
end

module Importer
  require 'fastercsv'
  
  @@path = Rails.root.join('tmp', 'import')
  
  def self.import_file(file, table, field_conversions = {}, truncate = false)
    ActiveRecord::Base.connection.execute("truncate #{table}") if truncate
    FasterCSV.open(path_to_file(file), 'r') do |csv|
      fields = csv.shift.collect {|f| field_conversions[f] ? field_conversions[f] : f }.join(', ')
      csv.each do |row|
        values = if block_given?
          yield row
        else
          map_data(row)
        end.join(', ')
        ActiveRecord::Base.connection.insert("insert ignore into #{table} (#{fields}) values (#{values})") unless values.blank?
      end
    end
  end  
  
  def self.update_table(file, table, field_conversions = {})
    FasterCSV.open(path_to_file(file), 'r') do |csv|
      fields = csv.shift.collect {|f| field_conversions[f] ? field_conversions[f] : f }
      csv.each do |row|
        values = if block_given?
          yield row
        else
          map_data(row)
        end
        set = (1..fields.size-1).to_a.map{|i| "#{fields[i]} = #{values[i]}"}.join(" AND ")
        sql = "UPDATE #{table} SET #{set} WHERE #{fields[0]} = #{values[0]}"
        puts sql
        ActiveRecord::Base.connection.update(sql)
      end
    end
  end
  
  def self.update_class(file, *args)
    options = args.extract_options!.symbolize_keys
    unless table = options.delete(:table)
      table = File.basename(file, '.csv')
    end
    klass = table.classify.constantize
    attributes_allowed = klass.new.attributes.keys.map{|k| k.to_sym}
    path = path_to_file(file)
    unless by = options.delete(:by)
      by = "id"
    end
    by = by.to_sym
    FasterCSV.read(path, :row_sep => (options[:mac] ? "\r" : "\n"), :headers => true, :skip_blanks => true, :header_converters => :symbol).each do |row|
      next if options[:restrict].is_a?(Array) && options[:restrict].any? && !options[:restrict].include?(row.to_hash[by])
      FEEDBACK.debug("row = #{row.to_hash.inspect}") if options[:debug]
      data = CsvParser.convert_row_to_data(row.to_hash)
      data.delete_if {|k,v| k == by || !attributes_allowed.include?(k)}
      if record = klass.send("find_by_#{by}", row[by])
        FEEDBACK.print_record(record) if options[:verbose]
        FEEDBACK.debug("  Updating attributes #{data.inspect}...") if options[:verbose]
        record.update_attributes(data) unless options[:debug]
      else
        FEEDBACK.error("#{table.humanize} not found '#{row[by]}'")
      end
    end
    Coverpage::Utils.parser_archive(path, :debug => options[:debug], :verbose => options[:verbose]) if options[:archive]
  end
  
  def self.map_data(row)
    row.map do |f|
      f.blank? ? 'null' : ActiveRecord::Base.connection.quote((f.respond_to?(:match) && f.match(/^\d+\/\d+\/\d+$/) ? f.to_date.to_s : f))
    end
  end
  
  def self.convert_data(f)
    f.blank? ? 'null' : ActiveRecord::Base.connection.quote((f.respond_to?(:match) && f.match(/\d+\/\d+\/\d+/) ? f.to_date.to_s : f))
  end
  
  def self.import_team_members(file)
    FasterCSV.open(path_to_file(file), 'r') do |csv|
      fields = csv.shift
      csv.each do |row|
        ActiveRecord::Base.connection.insert("update users set sales_team_id = #{row[1]} where id = #{row[3]}")
        if row[2].match(/head/i)
          ActiveRecord::Base.connection.insert("update sales_teams set managed_by = #{row[3]} where id = #{row[1]}")
        end
      end
    end
  end
  
  def self.import_addresses(file, truncate = false)
    ActiveRecord::Base.connection.execute("truncate addresses") if truncate
    FasterCSV.open(path_to_file(file), 'r') do |csv|
      fields = csv.shift
      postal_codes = PostalCode.all.inject({}) { |h, p| h[p.name] = p.id; h }
      csv.each do |row|
        ActiveRecord::Base.connection.insert("insert into addresses values (null, #{row.values_at(1, 3, 4, 5, 6, 7).map {|f| ActiveRecord::Base.connection.quote(f) }.join(', ')}, #{postal_codes[row[2]] ? postal_codes[row[2]] : 'null'})")
      end
    end
  end
  
  def self.import_transactions(file, truncate = false)
    ActiveRecord::Base.connection.execute("truncate posted_transactions") if truncate
    FasterCSV.open(path_to_file(file), 'r') do |csv|
      fields = csv.shift
      csv.each do |row|
        [8,9,11,13,14,15].each do |col|
          row[col] = (row[col].to_f * 100).to_i
        end
        row[0].gsub!(/\D/, '')
        ActiveRecord::Base.connection.insert("insert ignore into posted_transactions (id, customer_id, purchase_order, posted_on, shipped_on, transacted_on, amount, rep_base, sales_team_id, ship_amount, ship_sale_amount, transaction_amount, tax, type) values (#{map_data(row).values_at(0,1,3,5,6,7,8,9,10,11,13,14,15,16).join(', ')})")
      end
    end
  end
  
  def self.import_posted_transaction_lines(file, truncate = false)
    import_file(file, 'posted_transaction_lines', {
      'posted_tran_id' => 'posted_transaction_id',
      'qtybilled' => 'quantity',
      'unit_price' => 'unit_amount',
      'prodsale' => 'total_amount',
      'repbase' => 'rep_base'
    }, truncate) do |data|
      [4,5,6].each do |col|
        data[col] = (data[col].to_f * 100).to_i
      end
      map_data(data)
    end
  end
  
  def self.import_sales_targets(file, truncate = false)
    ActiveRecord::Base.connection.execute("truncate sales_targets") if truncate
    FasterCSV.open(path_to_file(file), 'r') do |csv|
      fields = csv.shift
      csv.each do |row|
        row[3] = row[3].to_i * 100
        ActiveRecord::Base.connection.execute("insert into sales_targets values (null, #{map_data(row).values_at(1,2,3).join(', ')})")
      end
    end
  end

  def self.path_to_file(file)
    File.join(@@path, file)
  end
  
end

# To change this template, choose Tools | Templates
# and open the template in the editor.

module Coverpage
  module Utils
    def self.str_to_boolean(str, *args)
      options = args.extract_options!.symbolize_keys
      tmp = str.to_s
      if options[:default] == true
        tmp.match(/^(false|f|no|n|0)$/i) == nil
      else
        tmp.match(/^(true|t|yes|y|1)$/i) != nil
      end
    end

    def self.str_to_array(str)
      tmp = str.to_s.gsub(',', ' ')
      tmp.split(/\s+/)
    end
  
    def self.str_to_choice(str, choices, *args)
      options = args.extract_options!.symbolize_keys
      choices.to_a if choices.is_a?(String)
      list = choices.map{|x| Regexp.escape(x.to_s)}.join('|')
      if str.blank?
        choice = options[:default]
      else
        if /^(#{list})$/i.match(str)
          choice = str.downcase
        else
          # choice = nil
          raise ArgumentError, "! Error: '#{str}' not in #{choices.inspect}", caller
        end
      end
      if choice.nil? && options[:allow_nil] == false
        raise ArgumentError, "! Error: '#{str}' not in #{choices.inspect}", caller
      end
      choice
    end
    
    def self.isbn_to_product(str)
      unless product = Product.find_by_isbn(str)
        raise ArgumentError, "! Error: Invalid ISBN #{str}"
      end
      return product
    end
    
    # Transform start_date, end_date, season keys to dates
    # NB: start_date and end_date take precedence over season
    def self.options_to_dates(options = {})
      if options.has_key?('start_date') || options.has_key?('end_date')
        start_date = options['start_date']
        end_date = options['end_date']
      else
        start_date, end_date = season_to_dates(options['season'])
      end
      return [start_date, end_date]
    end

    def self.impose_requirement(env, var)
      if env[var].blank?
        raise ArgumentError, "! Error: Must specify #{var}"
      else
        env[var]
      end
    end
    
    def self.print_variable(var, binding)
      raise ArgumentError, "Error: Must pass print_variable a string" unless var.is_a?(String) || var.is_a?(Array)
      var = var.to_a if var.is_a?(String)
      var.each { |x| puts "#{x} = #{eval(x, binding).inspect}" }
    end
    
    def self.print_collection(collection, options = {})
      print "#{sprintf("%5s", options[:i].to_i + 1)}. " unless options[:i].nil?
      puts "#{collection.send(options[:by] && collection.respond_to?(options[:by]) ? options[:by] : :id)} | #{collection.name} | #{collection.released_on}"
    end

    def self.print_product(product, options = {})
      print "#{sprintf("%5s", options[:i].to_i + 1)}. " unless options[:i].nil?
      puts "#{product.send(options[:by] && product.respond_to?(options[:by]) ? options[:by] : :id)} | #{product.name} | #{product.available_on}"
    end

    def self.print_products(products = [], options = {})
      products.each_with_index {|p, i| print_product(p, options.merge(:i => i))}
    end

    def self.test_directory(dir)
      Rails.logger.debug "testing dir #{dir}" unless Rails.blank?
      File.directory?(dir.to_s)
    end

    def self.test_file(file)
      Rails.logger.debug "testing #{file}" unless Rails.blank?
      File.exist?(file.to_s)
    end

    def self.season_to_dates(season = nil)
      # It's a bit of a misnomer but the current season is in calendar terms last season
      # TODO: as soon as available on is passed the product should be available
      # upcoming season should be today to six months in the future
      # new season should be six months ago to today
      # recent season should be 1 year ago to 6 month ago

      # Old way
      case season.to_s.downcase
      when 'new'
        # products published this season
        start_date = Product.recent_on + 1.day
        end_date = Product.new_on
      when 'upcoming'
        # products to be published next season
        start_date = Product.new_on + 1.day
        end_date = Product.upcoming_on
      when 'recent'
        start_date = Product.backlist_on + 1.day
        end_date = Product.recent_on
      when 'active'
        # products currently being sold
        start_date = nil
        end_date = Product.new_on
      when 'current'
        # recent + new
        start_date = Product.backlist_on + 1.day
        end_date = Product.new_on
      when 'backlist'
        # active - current
        start_date = nil
        end_date = Product.backlist_on
      when 'all'
        start_date = nil
        end_date = nil
      when ''
        start_date = nil
        end_date = Product.upcoming_on
      else
        raise ArgumentError, "! Error: Unsupported season '#{season}'"
      end
      FEEDBACK.debug "season_to_date returning '#{start_date}' - '#{end_date}'"
      return [start_date, end_date]
    end

    def self.parser_archive(path, options = {})
      filename = File.basename(path)
      extname = File.extname(filename)
      basename = filename.gsub(/#{extname}$/, '')
        puts "Archiving '#{filename}' to '#{CONFIG[:parser_archive_dir]}'..." if options[:verbose]
      unless options[:debug]
        dir = Rails.root.join(CONFIG[:parser_archive_dir])
        FileUtils.mkdir_p(dir)
        FileUtils.mv(path, "#{dir}/#{basename}-#{Time.now.strftime('%Y%m%d-%H%M')}#{extname}")
      end
    end

  end

end

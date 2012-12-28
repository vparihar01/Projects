module RakeUtils
  
  def self.str_to_boolean(str, *args)
    Coverpage::Utils.str_to_boolean(str, *args)
  end
  
  def self.str_to_array(str)
    tmp = str.to_s.gsub(',', ' ')
    tmp.split(/\s+/)
  end
  
  def self.str_to_choice(str, choices, *args)
    Coverpage::Utils.str_to_choice(str, choices, *args)
  end
  
  # print_variable: print variable to stdout
  #
  # usage:
  #   data = 'hi'
  #   RakeUtils.print_variable('data', binding)
  #   > data = hi
  # usage:
  #   var1 = 'hi'
  #   var2 = 'bye'
  #   RakeUtils.print_variable(%w(hi bye), binding)
  #   > var1 = hi
  #   > var2 = bye
  
  def self.print_variable(var, binding)
    Coverpage::Utils.print_variable(var,binding)
#    puts "Error: Must pass print_variable a string" unless var.is_a?(String) || var.is_a?(Array)
#    var = var.to_a if var.is_a?(String)
#    var.each { |x| puts "#{x} = #{eval(x, binding).inspect}" }
  end
  
  def self.impose_requirement(env, var)
    if env[var].blank?
      puts "! Error: Must specify #{var}"
      exit 1
    else
      env[var]
    end
  end
  
  def self.test_directory(dir, msg = "! Error: Directory not found")
    if !File.directory?(dir.to_s)
      puts "#{msg} '#{dir}'"
      exit(1)
    end
  end
  
  def self.test_file(file, msg = "! Error: File not found")
    if !File.exist?(file.to_s)
      puts "#{msg} '#{file}'"
      exit(1)
    end
  end
  
  def self.season_to_dates(season = nil)
    Coverpage::Utils.season_to_dates(season)
#    # It's a bit of a misnomer but the current season is in calendar terms last season
#    # TODO: as soon as available on is passed the product should be available
#    # upcoming season should be today to six months in the future
#    # new season should be six months ago to today
#    # recent season should be 1 year ago to 6 month ago
#
#    # Old way
#    case season.to_s.downcase
#    when 'new'
#      # products published this season
#      start_date = Product.recent_on + 1.day
#      end_date = Product.new_on
#    when 'upcoming'
#      # products to be published next season
#      start_date = Product.new_on + 1.day
#      end_date = Product.upcoming_on
#    when 'recent'
#      start_date = Product.backlist_on + 1.day
#      end_date = Product.recent_on
#    when 'active'
#      # products currently being sold
#      start_date = nil
#      end_date = Product.new_on
#    when 'current'
#      # recent + new
#      start_date = Product.backlist_on + 1.day
#      end_date = Product.new_on
#    when 'backlist'
#      # active - current
#      start_date = nil
#      end_date = Product.backlist_on
#    when 'all'
#      start_date = nil
#      end_date = nil
#    when ''
#      start_date = nil
#      end_date = Product.upcoming_on
#    else
#      puts "! Error: Unsupported season '#{season}'"
#      exit 1
#    end
#    return [start_date, end_date]
  end
  
end

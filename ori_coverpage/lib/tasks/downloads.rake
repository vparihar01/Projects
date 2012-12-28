namespace :downloads do
  include ActionDispatch::TestProcess
  require 'action_controller'
  require 'action_controller/test_case.rb'
  require 'rake_utils'

  desc 'Create/update products.csv for downloads.'
  task :update_active => :environment do
    # Create new data file
    puts "  Exporting data..."
    basename = ENV['basename'] = 'products'
    Rake::Task['export:csv'].invoke
    
    # Replace old download
    filename = "#{basename}.csv"
    path = Rails.root.join("tmp", filename).to_s
    RakeUtils.test_file(path)
    upload = fixture_file_upload(path, 'text/csv')
    if download = Download.find_by_filename(filename)
      puts "  Overwriting download (#{download.id})..."
      data = {:uploaded_data => upload, :updated_at => Time.now}
      download.update_attributes!(data)
    else
      puts "  Creating download..."
      data = {:title => "Active Titles", :description => "Contains ISBN numbers, copyright dates, prices, etc. for currently active titles.", :tag_list => "data", :uploaded_data => upload}
      Download.create(data)
    end
  end
  
  desc 'Create/update upcoming.csv for downloads.'
  task :update_upcoming => :environment do
    # Create new data file
    puts "  Exporting data..."
    ENV['season'] = 'upcoming'
    ENV['class'] = 'Product'
    ENV['basename'] = "products-upcoming-#{Product.upcoming_on.to_s(:mysql).gsub(/-/, '')}"
    Rake::Task['export:csv'].invoke

    # Create/update download
    filename = "#{ENV['basename']}.csv"
    path = Rails.root.join("tmp", filename).to_s
    RakeUtils.test_file(path)
    upload = fixture_file_upload(path, 'text/csv')
    if download = Download.find_by_filename(filename)
      puts "  Overwriting download (#{download.id})..."
      data = {:uploaded_data => upload, :updated_at => Time.now}
      download.update_attributes!(data)
    else
      puts "  Creating download..."
      data = {:title => "Upcoming Titles, #{Product.upcoming_season}", :description => "Product data for the upcoming #{Product.upcoming_season} season.", :tag_list => "data", :uploaded_data => upload}
      Download.create(data)
    end
  end
  
  desc 'Create/update products.xml for downloads.'
  task :update_onix => :environment do
    # Create new data file
    puts "  Exporting data..."
    ENV['class'] = 'Product'
    ENV['basename'] = "products"
    Rake::Task['export:xml'].invoke
    
    # Create/update download
    filename = "#{ENV['basename']}.xml"
    path = Rails.root.join("tmp", filename).to_s
    RakeUtils.test_file(path)
    upload = fixture_file_upload(path, 'text/xml')
    if download = Download.find_by_filename(filename)
      puts "  Overwriting download (#{download.id})..."
      data = {:uploaded_data => upload, :updated_at => Time.now}
      download.update_attributes!(data)
    else
      puts "  Creating download..."
      data = {:title => "Onix Product Data", :description => "Complete product data in Onix format.", :tag_list => "data", :uploaded_data => upload}
      Download.create(data)
    end
  end
  
  desc 'Create/update sellsheet for downloads. Required: season=[new|recent|upcoming]. Optional: debug, verbose.'
  task :update_sellsheet => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    season = Coverpage::Utils.str_to_choice(ENV['season'], %w(new recent upcoming), :allow_nil => false)
    Coverpage::Utils.print_variable(%w(debug verbose season), binding) if verbose
    season_name = Product.send("#{season}_season")
    filename = "sellsheets-#{season_name.split(' ')[1]}-#{season_name.split(' ')[0].downcase}.pdf"
    path = File.join(CONFIG[:ftp_dir], "sellsheets", filename).to_s
    Coverpage::Utils.test_file(path)
    upload = fixture_file_upload(path, 'application/pdf')
    if download = Download.find_by_filename(filename)
      puts "  Overwriting download (#{download.id})..." if verbose
      data = {:uploaded_data => upload, :updated_at => Time.now}
      download.update_attributes!(data) unless debug
    else
      puts "  Creating download..." if verbose
      title = "Sell Sheets, #{season_name}"
      description = "Marketing information, in 'flyer' form, regarding our #{season_name} titles"
      data = {:title => title, :description => description, :tag_list => "data", :uploaded_data => upload}
      Download.create(data) unless debug
    end
  end
  
end

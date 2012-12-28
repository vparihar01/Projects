namespace :utils do
  require 'rake_utils'
  require 'rake/clean'
  CLEAN.include('tmp/*.png', 'tmp/pdftool/*', 'tmp/ebooks/out/*', 'tmp/theme-*', 'tmp/*-deploy.yml')
  
  desc "Create the admin user"
  task :create_admin => :environment do
    user = Admin.create(:email => 'admin@example.com', :password => 'test', :password_confirmation => 'test', :name => 'admin', :category => 'Individual')
    if user.errors.any?
      puts "Failed"
      puts user.errors.inspect
    else
      puts "Succeeded"
      puts "Email: #{user.email}"
      puts "Password: #{user.password}"
    end
  end
  
  desc "Validate urls in links table"
  task :validate_links => :environment do
    Link.all.each_with_index do |link,i|
      puts "#{i+1}. #{link.url}"
      link.get_response # this method will set errors if any
      if link.errors.any?
        link.errors.each_full { |msg| puts "#{msg.gsub!(/^/,'    ')}" }
      end
      link.save_with_validation(false)
    end
  end
  
  desc "Process files in '#{CONFIG[:ebook_import_source_dir]}'. Rename such that isbn.pdf -> eisbn.pdf. Target directory is '#{CONFIG[:ebook_import_archive_dir]}'. Command line parameters: debug, verbose, force."
  task :rename_ebooks_by_eisbn => :environment do
    ENV['source'] = CONFIG[:ebook_import_source_dir]
    ENV['target'] = CONFIG[:ebook_import_archive_dir]
    ENV['ext'] = 'pdf'
    Rake::Task['utils:rename_files_by_eisbn'].invoke
  end
  
  desc "Process files in source directory. Rename such that isbn -> eisbn. Command line parameters: debug, verbose, force, source, target, ext."
  task :rename_files_by_eisbn => :environment do
    debug = RakeUtils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || RakeUtils.str_to_boolean(ENV['verbose'], :default => false))
    force = RakeUtils.str_to_boolean(ENV['force'], :default => false)
    source = RakeUtils.impose_requirement(ENV, 'source')
    target = RakeUtils.impose_requirement(ENV, 'target')
    ext = RakeUtils.impose_requirement(ENV, 'ext')
    ext.gsub!(/^\./, '')
    source_dir = Rails.root.join(source)
    target_dir = Rails.root.join(target)
    RakeUtils.test_directory(source_dir)
    RakeUtils.print_variable(%w(debug verbose force source target ext), binding)
    FileUtils.mkdir_p(target_dir, :noop => debug, :verbose => verbose)
    files = Dir.glob(File.join(source_dir, "*.#{ext}"))
    files.each_with_index do |path, i|
      # check each file for corresponding product, etc.
      filename = File.basename(path)
      isbn = File.basename(path, ".#{ext}")
      msg = "#{i+1}. #{filename}\n"
      if product = Title.find_by_isbn(isbn)
        msg += "  Product found: '#{product.name}' (#{product.id})...\n"
        if product.eisbn.blank?
          msg += "  eISBN blank -- Skipping file..."
          puts msg # whether verbose or not
        else
          # rename the file.
          Rails.logger.debug("ISBN: #{product.isbn}, eISBN: #{product.eisbn})")
          msg += "  Renaming file to '#{product.eisbn}.#{ext}'..."
          target_path = File.join(target_dir, "#{product.eisbn}.#{ext}")
          FileUtils.cp(path, target_path, :noop => debug, :verbose => verbose)
          puts msg if verbose
        end
      else
        msg += "  Product not found!"
        puts msg # whether verbose or not
        next
      end
    end
    puts "Finished renaming files." if verbose
  end
  
  desc "Upload a directory. url=[ftp://user:pwd@domain.com/path], source=[/path/to/source], ext=[jpg|tif]."
  task :upload => [:environment] do
    require 'uploader'
    debug = RakeUtils.str_to_boolean(ENV['debug'])
    verbose = (debug || RakeUtils.str_to_boolean(ENV['verbose']))
    ftp = Uploader.new(ENV['url'], :debug => debug, :verbose => verbose)
    result = ftp.put(ENV['source'], ENV['ext'])
    puts (result == true ? "Delivered" : "Failed")
  end
  
  desc "Create headline for new releases. Optional: debug, verbose."
  task :create_new_release_headline => [:environment] do
    debug = RakeUtils.str_to_boolean(ENV['debug'])
    verbose = (debug || RakeUtils.str_to_boolean(ENV['verbose']))
    count = Title.newly_available.count
    title = "#{Product.new_season} titles now available!"
    snippet = "#{CONFIG[:company_name]} has released #{count} new titles for #{Product.new_season}"
    body = "#{Product.new_season} titles now available! Visit our \"New Arrivals\":/shop/new_titles page."
    RakeUtils.print_variable(%w(debug verbose title snippet body), binding) if verbose
    FEEDBACK.verbose("Creating new headline...") if verbose
    Headline.create(:title => title, :snippet => snippet, :body => body) unless debug
  end
  
  desc "Create headline for new scribd catalog. Required: url. Optional: debug, verbose."
  task :create_new_catalog_headline => [:environment] do
    debug = RakeUtils.str_to_boolean(ENV['debug'])
    verbose = (debug || RakeUtils.str_to_boolean(ENV['verbose']))
    url = RakeUtils.impose_requirement(ENV, 'url')
    title = "Page Through Our #{Product.new_season} Catalog"
    snippet = "Page through our <a href=\"#{url}\" target=\"_blank\">#{Product.new_season} Catalog</a>, online."
    body = ""
    RakeUtils.print_variable(%w(debug verbose url title snippet body), binding) if verbose
    FEEDBACK.verbose("Creating new headline...") if verbose
    Headline.create(:title => title, :snippet => snippet, :body => body) unless debug
  end
end

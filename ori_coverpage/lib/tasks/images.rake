namespace :images do
  require 'rake_utils'
  
  desc "Process original images to create web images (s, m, l). Source directory must contain 'covers' and 'spreads' subdirectories. Command line parameters: 'source=[image_archive_dir]', 'verbose=[true|FALSE]', 'force=[true|FALSE]'."
  task :process => :environment do
    verbose = RakeUtils.str_to_boolean(ENV['verbose'])
    force = RakeUtils.str_to_boolean(ENV['force'])
    source = ENV['source'].blank? ? CONFIG[:image_archive_dir] : ENV['source']
    RakeUtils.test_directory(source)
    RakeUtils.print_variable(%w(verbose force source), binding) if verbose
    puts "Start processing images (#{Time.now.to_s(:us_with_time)})." if verbose
    ImageConverter.convert_image_directory(source, force)
    puts "Finished processing images (#{Time.now.to_s(:us_with_time)})." if verbose
  end
  
  desc "Create composites for assembly. Source directory must contain 'covers' and 'spreads' subdirectories. Command line parameters: 'source=[image_archive_dir]', 'verbose=[true|FALSE]', 'force=[true|FALSE]'."
  task :create_composites => :environment do
    verbose = RakeUtils.str_to_boolean(ENV['verbose'])
    force = RakeUtils.str_to_boolean(ENV['force'])
    source = ENV['source'].blank? ? CONFIG[:image_archive_dir] : ENV['source']
    RakeUtils.test_directory(source)
    RakeUtils.print_variable(%w(verbose force source), binding) if verbose
    puts "Start processing images (#{Time.now.to_s(:us_with_time)})." if verbose
    Assembly.all.each do |product|
      Coverpage::Utils.print_product(product, :by => :isbn)
      product.create_composite("covers", force)
      product.create_composite("spreads", force)
    end
    puts "Finished creating images (#{Time.now.to_s(:us_with_time)})." if verbose
  end
  
  desc "Create glider images for assembly. Source directory must contain 'covers' and 'spreads' subdirectories. Command line parameters: 'source=[image_archive_dir]', 'verbose=[true|FALSE]', 'force=[true|FALSE]'."
  task :create_gliders => :environment do
    verbose = RakeUtils.str_to_boolean(ENV['verbose'])
    force = RakeUtils.str_to_boolean(ENV['force'])
    source = ENV['source'].blank? ? CONFIG[:image_archive_dir] : ENV['source']
    RakeUtils.test_directory(source)
    RakeUtils.print_variable(%w(verbose force source), binding) if verbose
    puts "Start processing images (#{Time.now.to_s(:us_with_time)})." if verbose
    Assembly.all.each do |product|
      Coverpage::Utils.print_product(product, :by => :isbn)
      product.create_glider(force)
    end
    puts "Finished processing images (#{Time.now.to_s(:us_with_time)})." if verbose
  end

  desc "Process images, then create composites for assembly."
  task(:process_and_composite => [:process, :create_composites, :create_gliders])
  
  desc "Output image status to csv file. Optional: start_date, end_date, season, isbns, source=[#{CONFIG[:image_archive_dir]}], ext=[JPG|tif]."
  task :status => :environment do
    ext = Coverpage::Utils.str_to_choice(ENV['ext'], ImageRecipient::IMAGE_FORMATS, :default => 'jpg')
    source = ENV['source'].blank? ? CONFIG[:image_archive_dir] : ENV['source']
    Coverpage::Utils.test_directory(source)
    Coverpage::Utils.print_variable(%w(source ext), binding)
    products = get_products(ENV)
    file_path = Rails.root.join('tmp', 'images-status.csv')
    FasterCSV.open(file_path, "w", {:row_sep => "\n", :force_quotes => true}) do |csv|
      header = %w(name isbn series subseries responsible) + ImageRecipient::IMAGE_TYPES.map(&:singularize)
      csv << header
      products.all.each do |product|
        tmp = [product.name, product.isbn, product.series.try(:name), product.subseries.try(:name), nil]
        ImageRecipient::IMAGE_TYPES.each do |type|
          file = File.join(source, type, "#{product.isbn}.#{ext}")
          tmp << (File.exist?(file) ? 'YES' : '')
        end
        csv << tmp
      end
    end
    puts "Created #{file_path}"
  end
  
  # Helper method to convert ENV to products
  def get_products(options = {})
    klass = Title
    if options['isbns'].blank?
      start_date, end_date = Coverpage::Utils.options_to_dates(options)
      products = klass.find_using_options(:product_select => 'by_date', :start_date => start_date, :end_date => end_date)
    else
      isbns = options['isbns'].split(',').map{|i| i.strip}
      products = klass.find_using_options(:product_select => 'by_isbn', :isbns => isbns)
    end
    products.except(:order).order(:name)
  end

  desc "Check existence of images for products. Source directory must contain 'covers' and 'spreads' subdirectories. Options: start_date, end_date, season, isbns, verbose=[true|FALSE], source=[#{CONFIG[:image_archive_dir]}], ext=[JPG|tif]."
  task :check => :environment do
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'])
    ext = Coverpage::Utils.str_to_choice(ENV['ext'], ImageRecipient::IMAGE_FORMATS, :default => 'jpg')
    source = ENV['source'].blank? ? CONFIG[:image_archive_dir] : ENV['source']
    Coverpage::Utils.test_directory(source)
    Coverpage::Utils.print_variable(%w(verbose source ext), binding) if verbose
    products = get_products(ENV)
    ImageRecipient::IMAGE_TYPES.each do |type|
      puts "\nMissing #{type} (#{ext})"
      products.all.each do |product|
        file = File.join(source, type, "#{product.isbn}.#{ext}")
        unless File.exist?(file)
          if verbose
            Coverpage::Utils.print_product(product, :by => :isbn)
          else
            puts product.isbn
          end
        end
      end
    end
  end
  
  desc "Check existence of images for upcoming products in CONFIG[:image_archive_dir]."
  task :check_upcoming => :environment do
    ENV['season'] = 'upcoming'
    Rake::Task['images:check'].invoke
  end
  
  desc "Check existence of images for new products in CONFIG[:image_archive_dir]."
  task :check_new => :environment do
    ENV['season'] = 'new'
    Rake::Task['images:check'].invoke
  end
  
  desc "Create archive images from product download (PDF) if respective archive image is missing. Optional: target=[image_archive_dir], page=[10...], crop=[true|FALSE], color=[TRUE|false], midline=[TRUE|false], force=[true|FALSE], debug=[true|FALSE], verbose=[true|FALSE]."
  task :create_missing => [:environment] do
    options = get_image_options
    target = ENV['target'].blank? ? CONFIG[:image_archive_dir] : ENV['target']
    Coverpage::Utils.test_directory(target)
    titles = Title.all
    puts "Processing titles (#{titles.size} found):"
    titles.each_with_index do |p,i|
      Coverpage::Utils.print_product(p, :by => :isbn, :i => i)
      p.generate_images(target, options)
    end
  end
  
  desc "Create archive images from local PDF directory if respective archive image is missing. Optional: source, target=[image_archive_dir], page=[10...], crop=[true|FALSE], color=[TRUE|false], midline=[TRUE|false], force=[true|FALSE], debug=[true|FALSE], verbose=[true|FALSE]."
  task :create_missing_local => [:environment] do
    options = get_image_options
    source = ENV['source'].blank? ? CONFIG[:pdf_archive_dir] : ENV['source']
    target = ENV['target'].blank? ? CONFIG[:image_archive_dir] : ENV['target']
    Coverpage::Utils.test_directory(source)
    Coverpage::Utils.test_directory(target)
    titles = Title.all
    puts "Processing titles (#{titles.size} found):"
    titles.each_with_index do |p,i|
      Coverpage::Utils.print_product(p, :by => :isbn, :i => i)
      source_file = File.join(source, "#{p.isbn}.pdf")
      %w(covers spreads).each do |type|
        p.generate_image_from_ebook_file(source_file, type, target, options)
      end
    end
  end

  def get_image_options
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose']))
    force = Coverpage::Utils.str_to_boolean(ENV['force'])
    crop = Coverpage::Utils.str_to_boolean(ENV['crop'], :default => true)
    color = Coverpage::Utils.str_to_boolean(ENV['color'], :default => true)
    midline = Coverpage::Utils.str_to_boolean(ENV['midline'], :default => true)
    page = ((ENV['page'] && ENV['page'].to_i != 0) ? ENV['page'].to_i : nil)
    Coverpage::Utils.print_variable(%w(debug verbose force crop color midline page), binding) if verbose
    options = {
      :debug => debug,
      :verbose => verbose,
      :force => force,
      :crop => crop,
      :color => color,
      :midline => midline,
      :page => page,
    }
  end

  desc "Delete web images. Required: isbns. Optional: debug, verbose."
  task :delete => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    isbns = Coverpage::Utils.impose_requirement(ENV, 'isbns')
    isbns = isbns.split(',').map{|i| i.strip}
    Coverpage::Utils.print_variable(%w(debug verbose isbns), binding) if verbose
    isbns.each do |isbn|
      if product = Product.find_by_isbn(isbn)
        product.delete_web_images(:debug => debug, :verbose => verbose)
      end
    end
  end

  desc "Delete archive images. Required: isbns. Optional: debug, verbose, types, formats."
  task :delete_archive => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    isbns = Coverpage::Utils.impose_requirement(ENV, 'isbns')
    isbns = isbns.split(',').map{|i| i.strip}
    types = ENV['types'].blank? ? %w(covers spreads) : ENV['types'].to_s.split(',').map{|i| i.strip}
    formats = ENV['formats'].blank? ? ['*'] : ENV['formats'].to_s.split(',').map{|i| i.strip}
    Coverpage::Utils.print_variable(%w(debug verbose isbns types formats), binding) if verbose
    isbns.each do |isbn|
      if product = Product.find_by_isbn(isbn)
        types.each do |type|
          formats.each do |format|
            product.delete_archive_images(type, :format => format, :debug => debug, :verbose => verbose)
          end
        end
      end
    end
  end

  desc "Collect images for new assemblies. Optional: debug, verbose, type, new, limit, zip."
  task :collect_by_set => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    type = Coverpage::Utils.str_to_choice(ENV['type'], %w(covers spreads), :default => "covers")
    new = Coverpage::Utils.str_to_boolean(ENV['new'], :default => false)
    limit = ENV['limit'].blank? ? nil : ENV['limit'].to_i
    zip = Coverpage::Utils.str_to_boolean(ENV['zip'], :default => false)
    Coverpage::Utils.print_variable(%w(debug verbose type new limit zip), binding) if verbose
    dir = nil
    Assembly.newly_available.each do |assembly|
      dir = assembly.collect_images(type, :debug => debug, :verbose => verbose, :new => new, :limit => limit)
    end
    unless dir
      FEEDBACK.error "Failed" unless dir
      exit 1
    end
    if zip
      enclosing_dir = File.dirname(dir)
      dir_name = File.basename(enclosing_dir)
      FEEDBACK.verbose "Zipping directory '#{dir_name}'..." if verbose
      FileUtils.cd(File.dirname(enclosing_dir))
      cmd = "zip -r #{dir_name}.zip #{dir_name}"
      unless debug
        FileUtils.rm("#{enclosing_dir}.zip", :noop => debug, :verbose => verbose) if File.exist?("#{enclosing_dir}.zip")
        if ! system(cmd)
          FEEDBACK.error "Failed to execute system command '#{cmd}'"
        else
          FileUtils.rm_rf(enclosing_dir, :noop => debug, :verbose => verbose)
        end
      end
    end
  end
end

namespace :export do
  
  desc 'Export select product data. Optionally specify template (default: standard). Optionally specify start date and end date, season or ISBNs to filter products (eg, start_date=2008-08-02 end_date=2009-01-01, default: start_date = "", end_date = Product.new_on). Optionally specify class [PRODUCT|title|assembly]. Optionally specify basename (default: Product => products.csv). Optionally specify format ids (default: all). Optional: include_agency_price, include_sl_price, include_price_change, deactivate_sets, status.'
  task :default => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false))
    start_date, end_date = Coverpage::Utils.options_to_dates(ENV)
    isbns = (ENV['isbns'].blank? ? [] : ENV['isbns'].split(',').map{|i| i.strip})
    template = ENV['template'].blank? ? 'standard' : ENV['template']
    klass = ENV['class'].blank? ? 'Product' : ENV['class'].classify
    basename = ENV['basename'].blank? ? klass.tableize : ENV['basename'].gsub(/[.\/ ]/, "_").untaint
    format_ids = ENV['format_ids'].blank? ? Format.find_single_units.map(&:id) : ENV['format_ids'].scan(/\w+/)
    status = Coverpage::Utils.str_to_choice(ENV['status'], APP_STATUSES.keys, :allow_nil => true)
    include_agency_price = Coverpage::Utils.str_to_boolean(ENV['include_agency_price'], :default => false)
    include_sl_price = Coverpage::Utils.str_to_boolean(ENV['include_sl_price'], :default => false)
    include_price_change = Coverpage::Utils.str_to_boolean(ENV['include_price_change'], :default => false)
    deactivate_sets = Coverpage::Utils.str_to_boolean(ENV['deactivate_sets'], :default => false)
    Coverpage::Utils.print_variable(%w(debug verbose start_date end_date isbns template klass basename format_ids include_agency_price include_sl_price include_price_change deactivate_sets status), binding) if verbose
    products = klass.constantize.find_using_options(:product_select => (isbns.any? ? "by_isbn" : "by_date"), :start_date => start_date, :end_date => end_date, :isbns => isbns)
    file_path = ProductsExporter.execute(products, {:basename => basename, :data_format_ids => format_ids, :data_template => template, :data_include_agency_price => include_agency_price, :data_include_sl_price => include_sl_price, :data_include_price_change => include_price_change, :data_deactivate_sets => deactivate_sets, :status => status})
    puts "Created '#{file_path}'"
  end
  
  desc 'Export product data in ONIX format. Accepts same options as export:default.'
  task :xml => :environment do
    ENV['template'] = 'onix'
    Rake::Task['export:default'].invoke # ENV variables are available to invocation
  end
  
  desc 'Export product data in CSV format. Accepts same options as export:default.'
  task :csv => :environment do
    ENV['template'] = 'standard'
    Rake::Task['export:default'].invoke # ENV variables are available to invocation
  end

  desc "Export product data for grouped by set. Required: format_id. Optional: use_price_change = [true|FALSE], status, isbns, season, start_date, end_date."
  task :grouped => :environment do
    use_price_change = Coverpage::Utils.str_to_boolean(ENV['use_price_change'], :default => false)
    template = Coverpage::Utils.str_to_choice(ENV['template'], %w(edureference mba orderform standard replist), :default => 'standard')
    format_id = Coverpage::Utils.str_to_choice(ENV['format_id'], Format.find_single_units.map(&:id), :default => Format::DEFAULT_ID)
    options = {}
    format = Format.find(format_id).name
    Coverpage::Utils.print_variable(%w(format_id use_price_change template), binding)
    options[:basename] = "#{template}-#{format}".gsub(/[.\/ ]/, '').downcase.untaint
    options[:data_format_ids] = format_id
    options[:data_template] = template
    options[:use_price_change] = use_price_change
    product_formats = get_product_formats(ENV)
    if file_path = ProductsExporter.execute_as_grouped(product_formats, options)
      FEEDBACK.important "Created '#{file_path}'"
    else
      FEEDBACK.error "Failed to create export file"
    end
  end

  desc "Export product data for excel order form. Required: format_id. Optional: use_price_change = [true|FALSE], status, isbns, season, start_date, end_date."
  task :orderform => :environment do
    ENV['template'] = 'orderform'
    Rake::Task['export:grouped'].invoke # ENV variables are available to invocation
  end

  # Helper method to convert ENV to products
  def get_product_formats(options = {})
    format_id = Coverpage::Utils.str_to_choice(options['format_id'], Format.find_single_units.map(&:id), :default => Format::DEFAULT_ID)
    if options['isbns'].blank?
      start_date, end_date = Coverpage::Utils.options_to_dates(options)
      status = Coverpage::Utils.str_to_choice(options['status'], APP_STATUSES.keys, :allow_nil => true)
      base_product_formats = ProductFormat.find_using_options(:product_select => 'by_date', :start_date => start_date, :end_date => end_date).where('product_formats.format_id' => format_id)
      product_formats = base_product_formats.includes(:product).where('products.type' => 'Assembly')
      # If restricting to Assembly type returns no results, try Title
      unless product_formats.any?
        product_formats = base_product_formats.includes(:product).where('products.type' => 'Title')
      end
      product_formats = product_formats.where(:status => status) if status
    else
      isbns = options['isbns'].split(',').map{|i| i.strip}
      product_formats = ProductFormat.find_using_options(:product_select => 'by_isbn', :isbns => isbns).where('product_formats.format_id' => format_id)
    end
    product_formats.except(:order).order('products.name')
  end

end

namespace :distribute do
  desc 'Distribute specified asset type of select products to all recipients. Required: asset=[data|ebook|image]]. Optional: debug, verbose, season, start_date, end_date.'
  task :all => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    start_date, end_date = Coverpage::Utils.options_to_dates(ENV)
    asset = Coverpage::Utils.str_to_choice(ENV['asset'], %w(data ebook image), :allow_nil => false)
    Coverpage::Utils.print_variable(%w(debug verbose start_date end_date asset), binding) if verbose
    klass = "#{asset.titlecase}Recipient".classify.constantize
    results = klass.distribute_all(:debug => debug, :verbose => verbose, :product_select => 'by_date', :start_date => start_date, :end_date => end_date)
    results.each {|k, v| puts "#{k} = #{v.inspect}"}
  end

  desc 'Distribute select data to specified recipient. Options: debug, verbose, season, start_date, end_date, isbns, recipient, format_ids, template, class, status.'
  task :data => :environment do
    recipient, products = get_recipient_products(DataRecipient, ENV)
    recipient.distribute(products, :debug => ENV['debug'], :verbose => ENV['verbose'], :data_format_ids => (ENV['format_ids'] ? ENV['format_ids'].scan(/\w+/) : nil), :data_template => ENV['template'], :data_class => ENV['data_class'], :status => ENV['status'])
  end

  desc 'Distribute select ebooks to specified recipient. Options: debug, verbose, season, start_date, end_date, isbns, recipient, clean, force, eisbn, include_covers, include_data, include_manifest, suffix, cover_suffix.'
  task :ebooks => :environment do
    recipient, products = get_recipient_products(EbookRecipient, ENV)
    recipient.distribute(products, :debug => ENV['debug'], :verbose => ENV['verbose'], :force => ENV['force'], :clean => ENV['clean'], :ebook_use_eisbn => ENV['eisbn'], :ebook_include_covers => ENV['include_covers'], :ebook_include_data => ENV['include_data'], :ebook_include_manifest => ENV['include_manifest'], :ebook_suffix => ENV['suffix'], :ebook_cover_suffix => ENV['cover_suffix'])
  end
  
  desc 'Distribute select images to specified recipient. Options: debug, verbose, season, start_date, end_date, isbns, recipient, type, format, format_id, suffix, compress.'
  task :images => :environment do
    recipient, products = get_recipient_products(ImageRecipient, ENV)
    recipient.distribute(products, :debug => ENV['debug'], :verbose => ENV['verbose'], :force => ENV['force'], :clean => ENV['clean'], :image_types => ENV['type'], :image_formats => ENV['format'], :image_format_id => ENV['format_id'], :image_suffix => ENV['suffix'], :image_compress => ENV['compress'] )
  end

  desc 'Distribute price changes to all recipients. Options: debug, verbose.'
  task :price_changes => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    force = Coverpage::Utils.str_to_boolean(ENV['force'], :default => true)
    PriceChange.distribute(:debug => debug, :verbose => verbose, :force => force)
  end

  # Helper method to distribute:data, ebooks, images
  def get_recipient_products(klass, options = {})
    recipient = Coverpage::Utils.str_to_choice(options['recipient'], klass.all.map(&:name), :allow_nil => false)
    start_date, end_date = Coverpage::Utils.options_to_dates(options)
    isbns = (options['isbns'].blank? ? [] : options['isbns'].split(',').map{|i| i.strip})
    recipient = klass.find_by_name(recipient)
    products = recipient.products(:product_select => (isbns.any? ? "by_isbn" : "by_date"), :start_date => start_date, :end_date => end_date, :isbns => isbns)
    return [recipient, products]
  end
  
  desc "Setup test recipients. To destroy current test recipients, pass 'destroy=true'."
  task :setup_test => :environment do
    destroy = Coverpage::Utils.str_to_boolean(ENV['destroy'], :default => false)
    # Find current test recipient and delete
    Recipient.destroy_all("name like 'test%'") if destroy
    # Create new test recipients
    DataRecipient.create({
      :name => "test_onix",
      :ftp => CONFIG[:webmaster_ftp],
      :emails => CONFIG[:webmaster_email],
      :preferred_data_class => "Title",
      :preferred_data_template => "onix",
      :preferred_data_format_ids => [1, 3].to_yaml,
    })
    DataRecipient.create({
      :name => "test",
      :ftp => CONFIG[:webmaster_ftp],
      :emails => "",
      :preferred_data_class => "Product",
      :preferred_data_template => "standard",
      :preferred_data_format_ids => [1].to_yaml,
    })
    EbookRecipient.create({
      :name => "test_all",
      :ftp => CONFIG[:webmaster_ftp],
      :emails => "",
      :preferred_ebook_cover_suffix => "_cover",
      :preferred_ebook_include_manifest => "true",
      :preferred_ebook_suffix => "_ebook",
      :preferred_ebook_include_covers => "true",
      :preferred_ebook_include_data => "true",
      :preferred_ebook_use_eisbn => "true",
    })
    EbookRecipient.create({
      :name => "test",
      :ftp => CONFIG[:webmaster_ftp],
      :emails => CONFIG[:webmaster_email],
      :preferred_ebook_cover_suffix => "",
      :preferred_ebook_include_manifest => "false",
      :preferred_ebook_suffix => "",
      :preferred_ebook_include_covers => "false",
      :preferred_ebook_include_data => "false",
      :preferred_ebook_use_eisbn => "false",
    })
    ImageRecipient.create({
      :name => "test_zip",
      :ftp => CONFIG[:webmaster_ftp],
      :emails => "",
      :preferred_image_suffix => "_COVER",
      :preferred_image_types => ["covers"].to_yaml,
      :preferred_image_formats => ["tif"].to_yaml,
      :preferred_image_format_id => 2,
      :preferred_image_compress => "true",
    })
    ImageRecipient.create({
      :name => "test",
      :ftp => File.join(CONFIG[:webmaster_ftp], "covers"),
      :emails => CONFIG[:webmaster_email],
      :preferred_image_suffix => "_COVER",
      :preferred_image_types => ["covers"].to_yaml,
      :preferred_image_formats => ["jpg"].to_yaml,
      :preferred_image_format_id => 1,
      :preferred_image_compress => "false",
    })
  end
  
end

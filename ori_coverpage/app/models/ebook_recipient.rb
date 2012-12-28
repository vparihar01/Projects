class EbookRecipient < Recipient
  # preferences (using 'preference' engine) for the above non-standard Recipient fields
  preference :ebook_use_eisbn, :default => true
  preference :ebook_include_covers, :default => true
  preference :ebook_include_data, :default => true
  preference :ebook_include_manifest, :default => true
  preference :ebook_cover_suffix, :string, :default => ''
  preference :ebook_suffix, :string, :default => ''

  def products(options = {})
    # Ebooks are only applicable to Titles
    Title.find_using_options(options)
  end
  
  def distribute(products, args = {})
    options = get_options(args)
    result = distribute_assets(products, options)
    FEEDBACK.debug("result = #{result.inspect}") if options[:verbose]
    FEEDBACK.verbose(result == true ? "Delivered" : "Failed") if options[:verbose]
    result
  end

  protected

  def distribute_assets(products, options = {})
    result = false
    FEEDBACK.debug "processing products..." if options[:verbose]
    
    # raise ArgumentError, "! Error: No products found." unless products.any?
    unless products.count > 0
      FEEDBACK.important("! Error: No products found.")
      return false
    end

    target_dir = Rails.root.join("tmp", "distribute")
    if File.exist?(target_dir)
      if options[:force]
        FileUtils.rm_r(target_dir, :noop => options[:debug], :verbose => options[:verbose])
      else
        raise "! Error: Target directory (#{target_dir}) exists. Try option 'force=true'."
      end
    end
    mkdir_p(target_dir, :noop => options[:debug], :verbose => options[:verbose])

    # should only export product data and ftp cover/spread image if the pdf is found
    # products = filter_products(products)
    ok = []
    products.each do |product|
      if product.download && File.exist?(product.download.full_filename)
        # Ensure pdf format exists
        if pf = product.pdf_format
          unless options[:status].blank? || pf.status.try(:upcase) == options[:status].try(:upcase)
            FEEDBACK.verbose "#{product.name} (#{product.isbn}) -- Status not '#{options[:status]}'"
          else
            ok << product
          end
        else
          FEEDBACK.error "#{product.name} (#{product.isbn}) -- Must create pdf format and assign eISBN"
        end
      else
        FEEDBACK.error "#{product.name} (#{product.isbn}) -- Download not found"
      end
    end
    
    # FEEDBACK.debug "done filtering products" if options[:verbose]
    ok.each_with_index do |product, i|
      FEEDBACK.debug "#{sprintf('%4s', i+1)}. #{product.name} (#{product.isbn})"
      # Collect pdf
      source = product.download.full_filename
      ext = File.extname(source).sub('.','')
      basename = (options[:ebook_use_eisbn] == true ? product.eisbn : product.isbn)
      target = File.join(target_dir, "#{basename}#{options[:ebook_suffix]}.#{ext}")
      FEEDBACK.debug "Copy #{source} -> #{target}" if options[:verbose] == true
      FileUtils.cp(source, target, :noop => options[:debug], :verbose => options[:verbose])
      # Collect cover
      self.class.collect_image(product, File.join(CONFIG[:image_archive_dir], "covers"), target_dir, "jpg", (options[:ebook_use_eisbn] == true ? 'pdf' : 'default'), options[:ebook_cover_suffix], options) if options[:ebook_include_covers] == true
    end
    # Collect data/manifest
    if options[:ebook_include_data] == true || options[:ebook_include_manifest] == true
      file_path = ProductsExporter.execute(Title.where("id IN (?)", ok), {:data_format_ids => '2', :data_template => 'formats', :status => options[:status]})
      FEEDBACK.verbose "Created '#{file_path}'"
      if options[:ebook_include_data] == true
        FEEDBACK.debug "Copy #{file_path} -> #{target_dir}" if options[:verbose] == true
        FileUtils.cp(file_path, target_dir, :noop => options[:debug], :verbose => options[:verbose])
      end
    end
    FEEDBACK.verbose "Collecting files from #{target_dir}" if options[:verbose]
    # FTP items collected
    if Dir.glob("#{target_dir}/*").any?
      FEEDBACK.verbose "Uploading to #{self.ftp}" if options[:verbose]
      # desc "Upload a directory. url=[ftp://user:pwd@domain.com/path], source=[/path/to/source], ext=[jpg|tif]."
      server = Uploader.new(self.ftp, :debug => options[:debug], :verbose => options[:verbose])
      result = (options[:debug] ? true : server.put(target_dir))       # result should be set to true (if execution reaches this point) in debug mode
      # Send email notification
      unless self.emails.nil? || self.emails.blank? || result == false
        FEEDBACK.verbose "Notifying #{self.emails.inspect}..."
        file_path = nil unless options[:ebook_include_manifest] == true
        email = NotificationMailer.ebooks_delivered(self.emails, :file_path => file_path, :server => server)
        email.deliver unless options[:debug]
      end
    else
      FEEDBACK.verbose "No files collected to upload."
    end
    FileUtils.rm_r(target_dir, :noop => options[:debug], :verbose => options[:verbose]) if options[:clean]
    result
  end

  def get_options(args = {})
    options = super(args)

    # Verify and convert given values
    options[:ebook_use_eisbn] = Coverpage::Utils.str_to_boolean(options[:ebook_use_eisbn], :default => false) if options[:ebook_use_eisbn]
    options[:ebook_include_covers] = Coverpage::Utils.str_to_boolean(options[:ebook_include_covers], :default => false) if options[:ebook_include_covers]
    options[:ebook_include_data] = Coverpage::Utils.str_to_boolean(options[:ebook_include_data], :default => false) if options[:ebook_include_data]
    options[:ebook_include_manifest] = Coverpage::Utils.str_to_boolean(options[:ebook_include_manifest], :default => false) if options[:ebook_include_manifest]
    options[:status] = Coverpage::Utils.str_to_choice(options[:status], APP_STATUSES.keys, :allow_nil => true).try(:upcase)

    # Use recipient values as default. Overwrite with non-nil given values
    options = {
      :ebook_use_eisbn => self.preferred_ebook_use_eisbn,
      :ebook_include_covers => self.preferred_ebook_include_covers,
      :ebook_include_data => self.preferred_ebook_include_data,
      :ebook_include_manifest => self.preferred_ebook_include_manifest,
      :ebook_suffix => self.preferred_ebook_suffix,
      :ebook_cover_suffix => self.preferred_ebook_cover_suffix,
    }.merge(options.delete_if{|k, v| v.nil?})
    
    FEEDBACK.debug("AFTER DataRecipient.get_options")
    FEEDBACK.debug("options = #{options.inspect}")
    options
  end

end

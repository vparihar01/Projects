class ImageRecipient < Recipient
  IMAGE_TYPES = Dir.glob("#{CONFIG[:image_archive_dir]}/**").select {|d| File.directory?(d)}.map {|d| d.sub(/#{CONFIG[:image_archive_dir]}\//, '')}.freeze
  IMAGE_FORMATS = ['jpg', 'tif'].freeze
  
  include ActiveModel::Validations
  class ImageTypesValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      # value is yaml array
      value_array = value.blank? ? [] : YAML.load(value)
      value_array.each do |v|
        record.errors[attribute] << "unacceptable value '#{v}'" unless IMAGE_TYPES.include?(v)
      end if value_array.any?
    end
  end
  class ImageFormatsValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      # value is yaml array
      value_array = value.blank? ? [] : YAML.load(value)
      value_array.each do |v|
        record.errors[attribute] << "unacceptable value '#{v}'" unless IMAGE_FORMATS.include?(v)
      end if value_array.any?
    end
  end
  
  # preferences (using 'preference' engine) for the above non-standard Recipient fields
  preference :image_suffix, :string, :default => ''
  preference :image_compress, :default => false
  preference :image_format_id, :integer, :default => Format::DEFAULT_ID
  preference :image_types, :string, :default => ["covers"].to_yaml # Store in yaml array format
  preference :image_formats, :string, :default => ["jpg"].to_yaml # Store in yaml array format
  
  validates :preferred_image_types, :presence => true, :image_types => true
  validates :preferred_image_formats, :presence => true, :image_formats => true
  
  def image_type_array
    preferred_image_types.blank? ? [] : YAML.load(preferred_image_types)
  end
  
  def image_format_array
    preferred_image_formats.blank? ? [] : YAML.load(preferred_image_formats)
  end

  def distribute(products, args = {})
    options = get_options(args)
    result = distribute_assets(products, options)
    FEEDBACK.debug("result = #{result.inspect}") if options[:verbose]
    FEEDBACK.verbose(result.values.include?(false) ? "Failed" : "Delivered" ) if options[:verbose]
    result
  end

  protected

  def distribute_assets(products, options = {})
    result = {}
    target_dir = nil
    options[:image_formats].each do |format|
      options[:image_types].each do |type|
        target_name = "#{CONFIG[:export_basename]}-#{type}-#{format}"
        unless products.count > 0
          FEEDBACK.error("No products found.")
          result[target_name] = false
          next
        end
        if self.ftp.blank?
          # Do not create asset package -- simply sending images_available email notification
          result[target_name] = true
        else
          # If uploading multiple types, need to place in type subdirectory to avoid overwrite
          url = options[:image_types].size > 1 && options[:image_compress] != true ? File.join(self.ftp, type) : self.ftp
          # Create asset package in tmp directory for ftp upload
          parent_dir = Rails.root.join("tmp")
          target_dir = File.join(parent_dir, target_name)
          if File.exist?(target_dir)
            if options[:force]
              FileUtils.rm_r(target_dir, :noop => options[:debug], :verbose => options[:verbose])
            else
              FEEDBACK.error "Target directory ('#{target_dir}') exists. Try option 'force=true'."
              result[target_name] = false
              next
            end
          end
          mkdir_p(target_dir, :noop => options[:debug], :verbose => options[:verbose])
          ok = []
          products.each do |product|
            image = File.join(CONFIG[:image_archive_dir], type, "#{product.isbn}.#{format}")
            if File.exist?(image)
              ok << product
            else
              FEEDBACK.error "#{product.name} (#{product.isbn}) -- Image not found '#{image}'"
              result[target_name] = false
              next
            end
          end
          ok.each_with_index do |product, i|
            FEEDBACK.debug "#{sprintf('%4s', i+1)}. #{product.name} (#{product.isbn})"
            self.class.collect_image(product, File.join(CONFIG[:image_archive_dir], type), target_dir, format, options[:image_format_id], options[:image_suffix], options)
          end
          # FTP items collected
          if Dir.glob("#{target_dir}/*").any?
            if options[:image_compress] == true
              FEEDBACK.debug "Compressing..."
              FileUtils.cd(parent_dir)
              zip_name = "#{target_name}-#{Time.now.strftime("%Y%m%d%H%M")}.zip"
              cmd = "zip -r #{zip_name} #{target_name}"
              # if the system command fails
              if ! system(cmd)
                FEEDBACK.error "Failed to execute system command '#{cmd}'"
                result[target_name] = false
                next
              end
              FileUtils.rm_r(target_dir, :noop => options[:debug], :verbose => options[:verbose])
              mkdir_p(target_dir, :noop => options[:debug], :verbose => options[:verbose])
              FileUtils.mv(File.join(parent_dir, zip_name), target_dir)
              FileUtils.cd(Rails.root.to_s)
            end
            # desc "Upload a directory. url=[ftp://user:pwd@domain.com/path], source=[/path/to/source], ext=[jpg|tif]."
            server = Uploader.new(url, :debug => options[:debug], :verbose => options[:verbose])
            result[target_name] = server.put(target_dir)
          else
            FEEDBACK.error "No files collected to upload."
            result[target_name] = false
          end
          FileUtils.rm_r(target_dir, :noop => options[:debug], :verbose => options[:verbose]) if options[:clean]
        end # if self.ftp.blank?
      end # types loop
    end # formats loop
    # Send email notification
    unless self.emails.blank? || !result.values.include?(true)
      FEEDBACK.verbose "Notifying #{self.emails.inspect}..."
      if self.ftp.blank?
        email = NotificationMailer.images_available(self.emails)
      else
        email = NotificationMailer.images_delivered(self.emails, :server => Uploader.new(self.ftp))
      end
      email.deliver unless options[:debug]
    end
    result
  end

  def get_options(args = {})
    options = super(args)

    # Verify and convert given values
    options[:image_compress] = Coverpage::Utils.str_to_boolean(options[:image_compress], :default => false) if options[:image_compress]
    options[:image_format_id] = Coverpage::Utils.str_to_choice(options[:image_format_id], Format.find_single_units.map(&:id)) if options[:image_format_id]
    options[:image_types] = [Coverpage::Utils.str_to_choice(options[:image_types], IMAGE_TYPES)] if options[:image_types]
    options[:image_formats] = [Coverpage::Utils.str_to_choice(options[:image_formats], IMAGE_FORMATS)] if options[:image_formats]
    options[:status] = Coverpage::Utils.str_to_choice(options[:status], APP_STATUSES.keys, :allow_nil => true).try(:upcase)

    # Use recipient values as default. Overwrite with non-nil given values
    options = {
      :image_suffix => self.preferred_image_suffix,
      :image_compress => self.preferred_image_compress,
      :image_format_id => self.preferred_image_format_id,
      :image_types => self.image_type_array,
      :image_formats => self.image_format_array,
    }.merge(options.delete_if{|k, v| v.nil?})
    
    FEEDBACK.debug("AFTER ImageRecipient.get_options")
    FEEDBACK.debug("options = #{options.inspect}")
    options
  end

end

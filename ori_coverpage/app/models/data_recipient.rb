class DataRecipient < Recipient

  class DataFormatIdsValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      format_ids = Format.find_single_units.map(&:id)
      # value is yaml array
      value_array = value.blank? ? [] : YAML.load(value)
      value_array.each do |v|
        record.errors[attribute] << "unacceptable value '#{v}'" unless format_ids.include?(v.to_i)
      end if value_array.any?
    end
  end
  
  # preferences (using 'preference' engine) for the above non-standard Recipient fields
  preference :data_template, :string, :default => 'standard'
  preference :data_format_ids, :string, :default => [1].to_yaml
  preference :data_class, :string, :default => 'Title'
  preference :data_include_agency_price, :default => false
  preference :data_include_sl_price, :default => false
  preference :data_include_price_change, :default => false
  preference :data_basename_prefix, :string, :default => CONFIG[:export_basename]
  preference :data_basename_include_template, :default => true
  preference :data_basename_include_date, :default => true
  preference :data_basename_join_with, :string, :default => '-'
  preference :data_deactivate_sets, :default => true

  validates :preferred_data_template, :presence => true, :inclusion => { :in => ProductsExporter::TEMPLATES }
  validates :preferred_data_class, :presence => true, :inclusion => { :in => Product::TYPES.keys }
  validates :preferred_data_format_ids, :presence => true, :data_format_ids => true
  
  def data_format_id_array
    preferred_data_format_ids.blank? ? [] : YAML.load(preferred_data_format_ids)
  end

  def products(options = {})
    self.preferred_data_class.classify.constantize.find_using_options(options)
  end

  def distribute(products, args = {})
    options = get_options(args)
    file_path = ProductsExporter.execute(products, options)
    result = distribute_assets(file_path, options)
    FEEDBACK.debug("result = #{result.inspect}") if options[:verbose]
    FEEDBACK.verbose(result == true ? "Delivered" : "Failed") if options[:verbose]
    result
  end

  def data_basename(options = {})
    template = (self.preferred_data_basename_include_template == true ? (options[:data_template].blank? ? self.preferred_data_template : options[:data_template]) : nil)
    date = (self.preferred_data_basename_include_date == true ? Date.today.strftime("%Y%m%d") : nil)
    prefix = (self.preferred_data_basename_prefix.blank? ? nil : self.preferred_data_basename_prefix)
    [prefix, template, date].compact.join(self.preferred_data_basename_join_with)
  end

  protected

  def distribute_assets(file_path, options = {})
    FEEDBACK.verbose("Distributing '#{file_path}'...") if options[:verbose]
    return false unless file_path && File.exist?(file_path)
    result = true
    unless self.ftp.blank?
      server = Uploader.new(self.ftp, :debug => options[:debug], :verbose => options[:verbose])
      result = server.put(file_path)
    end
    if result && !self.email_array.blank?
      if self.ftp.blank?
        # Compose email with attachment
        email = NotificationMailer.data_delivered(self.email_array, :file_path => file_path)
      else
        # Compose email without attachment, data sent via ftp
        email = NotificationMailer.data_delivered(self.email_array, :server => server)
      end
      email.deliver unless options[:debug]
    end
    FEEDBACK.debug("Done") if options[:verbose]
    result
  end

  def get_options(args = {})
    options = super(args)

    # Verify and convert given values
    if options[:data_format_ids] && options[:data_format_ids].any?
      options[:data_format_ids].each {|format_id| Coverpage::Utils.str_to_choice(format_id, Format.find_single_units.map(&:id))}
    else
      options[:data_format_ids] = nil
    end
    options[:data_template] = Coverpage::Utils.str_to_choice(options[:data_template], ProductsExporter::TEMPLATES.keys) if options[:data_template]
    options[:data_class] = Coverpage::Utils.str_to_choice(options[:data_class], Product::TYPES.keys) if options[:data_class]
    options[:status] = Coverpage::Utils.str_to_choice(options[:status], APP_STATUSES.keys, :allow_nil => true).try(:upcase)

    # Use recipient values as default. Overwrite with non-nil given values
    options = {
      :data_format_ids => self.data_format_id_array,
      :data_template => self.preferred_data_template,
      :data_class => self.preferred_data_class,
      :data_include_agency_price => self.preferred_data_include_agency_price,
      :data_include_sl_price => self.preferred_data_include_sl_price,
      :data_include_price_change => self.preferred_data_include_price_change,
      :data_deactivate_sets => self.preferred_data_deactivate_sets,
    }.merge(options.delete_if{|k, v| v.nil?})

    # Do not override onix template with price_change template
    options[:data_template] = self.preferred_data_template if options[:data_template] == 'price_change' && /^onix/.match(self.preferred_data_template)

    # Calculate basename. If blank, then products_exporter will use default basename
    basename = self.data_basename(:data_template => options[:data_template])
    options[:basename] = basename unless basename.blank?

    FEEDBACK.debug("AFTER DataRecipient.get_options")
    FEEDBACK.debug("options = #{options.inspect}")
    options
  end

end

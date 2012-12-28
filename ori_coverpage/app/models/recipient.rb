class Recipient < ActiveRecord::Base
  SUBCLASSES = ['DataRecipient', 'EbookRecipient', 'ImageRecipient'].sort_by { |x| x.downcase }.freeze
  ASSETS     = SUBCLASSES.map {|x| x.sub(/Recipient$/, '').downcase}.freeze

  has_many :stored_preferences, :as => :owner, :class_name => 'Preference', :dependent => :destroy # :dependent => :destroy is not in preferences, patching here

  validates :name, :presence => true, :uniqueness => { :scope => :type }
  validates :emails, :format => {:allow_blank => true, :with => /\A(([^@,]*[\<]*)([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})([>]*[,]{0,1}[ ]*)*)+\Z/i}
  validates :ftp, :presence => {:if => :ftp_required?, :message => "can't be blank if type is EbookRecipient or email is blank"}, :format => {:allow_blank => true, :with => /\A(s*ftp:\/\/([^@,\s]+):([^@,\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})([>]*[,]{0,1}[ ]*)*\/?.*)+\Z/i, :message => "must be formatted as ftp://user:password@domain.com"}

  scope :automatic, where("is_automatic = ?", true)

  def email_array
    # Must be comma-separated (not space-separated) to handle format "John Doe <john@doe.com>"
    emails.blank? ? [] : emails.split(',').map{|i| i.strip}
  end

  def to_s
    name
  end

  def products(options = {})
    # Used to find applicable assets, override in Recipient subclasses
    Product.find_using_options(options)
  end

  def self.subclasses_dropdown(options = {})
    list = SUBCLASSES.map {|s| [s.sub(/Recipient$/, ''), s]}
    list.insert(0, '') if options[:include_blank] == true
    list
  end

  def self.to_dropdown
    order(:name).map(&:name)
  end

  # Prepare and distribute asset for all recipients
  def self.distribute_all(options = {})
    results = {}
    self.automatic.each do |recipient|
      # Dupe options so that they're not overridden by recipient
      opts = options.dup
      # Product class is recipient specific
      products = recipient.products(opts)
      # Results placed in hash with recipient as key
      results[recipient.name] = recipient.distribute(products, opts)
    end
    results
  end

  protected

  # used by EbookRecipient and ImageRecipient subclasses
  def self.collect_image(product, source_dir = File.join(CONFIG[:image_archive_dir], "covers"), target_dir = Rails.root.join("tmp", "distribute"), format = 'jpg', format_id = Format::DEFAULT_ID, suffix = '', options = {})
    source = File.join(source_dir, "#{product.isbn}.#{format}")
    if File.exist?(source)
      ext = File.extname(source).sub('.','')
      pf = product.product_formats.where("product_formats.format_id = ?", format_id).first
      if pf && basename = pf.isbn
        unless options[:status].blank? || pf.status.try(:upcase) == options[:status].try(:upcase)
          FEEDBACK.warning "#{product.name} (#{product.isbn}) -- Status not '#{options[:status]}'"
        else
          target = File.join(target_dir, "#{basename}#{suffix}.#{ext}")
          FileUtils.cp(source, target, :noop => options[:debug], :verbose => options[:verbose])
        end
      else
        FEEDBACK.error "#{product.name} (#{product.isbn}) -- Format not found '#{format_id}'"
      end
    else
      FEEDBACK.error "#{product.name} (#{product.isbn}) -- Image missing '#{source}'"
    end
  end
  
  def ftp_required?
    if self['type'] == "EbookRecipient"
      true
    else
      emails.blank?
    end
  end
  
  def get_options(args =  {})
    FEEDBACK.debug("BEFORE Recipient.get_options")
    FEEDBACK.debug("args = #{args.inspect}")

    options = args.symbolize_keys

    # Setup defaults. Verify and convert given values
    options[:debug] = Coverpage::Utils.str_to_boolean(options[:debug], :default => false)
    options[:verbose] = Coverpage::Utils.str_to_boolean(options[:verbose], :default => true)
    options[:force] = Coverpage::Utils.str_to_boolean(options[:force], :default => true)
    options[:clean] = Coverpage::Utils.str_to_boolean(options[:clean], :default => true)

    FEEDBACK.debug("AFTER Recipient.get_options")
    FEEDBACK.debug("options = #{options.inspect}")
    options
  end

end

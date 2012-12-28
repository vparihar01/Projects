class Link < ActiveRecord::Base
  has_and_belongs_to_many :products, :uniq => true
  
  ERROR_MESSAGES = {
    :redirects => 3,
    :wrong_response => { Net::HTTPMovedPermanently => "has been moved", Net::HTTPResponse => "is not working correctly" },
    :wrong_protocol => "must be the URL for a website",
    :malformed_url => 'is an invalid URL (did you remember the "http://"?)',
    :no_response => "is not accessible",
    :timeout => "is taking too long to respond",
    :too_many_redirects => "had too many redirects",
    :valid_responses => [ Net::HTTPSuccess ],
    :request_class => Net::HTTP::Get
  }

  validates :url, :presence => true
  validates_http_url :url, ERROR_MESSAGES

  # returns links that are not considered broken or deleted
  scope :ok, where("deleted_at IS NULL AND code = 200")
  
  def link_title
    if ! self.title.blank? 
      self.title
    elsif ! self.meta_title.blank?
      self.meta_title
    else 
      self.url
    end
  end
  
  def self.kid_items
    where("deleted_at IS NULL AND is_kids = 1 AND is_highlight = 1 AND code = 200").order("title ASC")
  end
  
  def self.adult_items
    where("deleted_at IS NULL AND is_adults = 1 AND is_highlight = 1 AND code = 200").order("title ASC")
  end
  
  def is_ok?
    self.code == 200
  end
  
  # mark as modified
  def mark_as_modified
    self.updated_at = Time.now
    self.save
  end
  
  # add 1 to the views count for the associated link
  def mark_as_viewed
    self.views += 1
    self.save( :validate => false)
  end
  
  def get_response
    begin
      uri = URI.parse(self.url)
      if uri.kind_of?(URI::HTTP)
        Link.validate_http_url_with_redirection(ERROR_MESSAGES, self, :url, uri.host, uri.port, uri.path)
      else
        self.errors.add :url, ERROR_MESSAGES[:wrong_protocol]
      end
    rescue URI::InvalidURIError
      self.errors.add :url, ERROR_MESSAGES[:malformed_url]
    rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH
      self.errors.add :url, ERROR_MESSAGES[:no_response]
    rescue Timeout::Error, Errno::ETIMEDOUT
      self.errors.add :url, ERROR_MESSAGES[:timeout]
    end
  end

  def self.to_dropdown
    all.sort_by(&:link_title).collect {|x| [x.link_title, x.id]}
  end

  def self.remove_duplicate_product_assignments
    self.all.each do |link|
      ids = link.product_ids.uniq
      if ids.any?
        link.products.clear
        link.product_ids = ids
      end
    end
  end
  
  def assign_assemblies(options = {})
    FEEDBACK.verbose("#{self.url}") if options[:verbose]
    self.products.where("type = ?", "Title").each do |product|
      product.assemblies.each do |assembly|
        unless self.products.include?(assembly)
          FEEDBACK.verbose("  Assigning '#{assembly.name}' (#{assembly.id}) to Link (#{self.id})...") if options[:verbose]
          self.products << assembly unless options[:debug]
        else
          FEEDBACK.verbose("  Skip: '#{assembly.name}' (#{assembly.id}) already assigned to Link (#{self.id})") if options[:verbose]
        end
      end
    end
  end

  def merge(source, options = {})
    FEEDBACK.verbose "Updating link assignments (#{source.id} => #{self.id})..." if verbose
    rows = ActiveRecord::Base.connection.update("UPDATE links_products SET link_id = '#{self.id}' WHERE link_id = '#{source.id}'") unless debug
    FEEDBACK.verbose "  #{rows} row(s) affected..." if verbose && rows
    # merge data
    [:description, :title, :proprietary_id].each do |col|
      if self.send(col).blank? && !source.send(col).blank?
        self.update_attribute(col, source.send(col)) unless debug
      end
    end
    self.update_attribute(:views, self.views + source.views)
    FEEDBACK.verbose "Destroying link (#{source.id})..." if verbose
    source.destroy unless debug
  end

end

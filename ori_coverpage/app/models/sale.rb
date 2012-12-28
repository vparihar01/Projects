class Sale < LineItemCollection
  VALID_STATUSES = %w(Submitted Accepted Shipped Paid Cancelled)
  has_many :status_changes, :as => :status_changeable, :dependent => :delete_all, :order => 'created_at asc'
  before_save :create_status_change_if_changed
  validates :status, :inclusion => { :in => VALID_STATUSES },
                     :allow_nil => true
  validates :user_id, :presence => true
                         
  def create_status_change_if_changed
    if self.status_changed?
      self.send("mark_as_#{self.status.downcase}") if self.respond_to?("mark_as_#{self.status.downcase}")
      self.status_changes.create(:status => self.status)
      NotificationMailer.sale_change(self, self.status).deliver if CONFIG[:email_sale_status] == true && self.user.preferred_email_sale_status
    end
  end
  
  def cart=(cart)
    self.line_items = cart.line_items
  end

  def total_amount
    (self.amount.nil? ? 0 : self.amount) +
      (self.alsquiz_amount.nil? ? 0 : self.alsquiz_amount) +
      (self.tax.nil? ? 0 : self.tax) + 
      (self.shipping_amount.nil? ? 0 : self.shipping_amount) +
      (self.processing_amount.nil? ? 0 : self.processing_amount) - 
      self.discount_amount
  end

  def discounted?
    self.discount_amount > 0
  end
  
  def discount_amount
    self[:discount_amount]
  end
  
  # TODO verify that downloads are added correctly - adjust code if necessary
  # TODO the code inserts to downloads pre-existing downloads too -> duplicates don't make sense...
  def mark_as_paid
    # Process the credit card, if necessary
    self.card_authorization.capture if self.card_authorization
    
    # Give the user access to the downloads associated with
    # products included in the order
    files = self.line_items.collect(&:product).inject([]) do |files, product|
      files.push product.download
      files += product.downloads if product.respond_to?(:downloads)
      files
    end.flatten.compact.uniq
    self.user.downloads << files
  end
  
  def mark_as_cancelled
    # Void the credit card authorization, if necessary
    self.card_authorization.void_auth if self.card_authorization
  end
  
end

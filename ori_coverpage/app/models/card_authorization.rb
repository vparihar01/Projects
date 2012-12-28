class CardAuthorization < ActiveRecord::Base
  belongs_to :line_item_collection
  belongs_to :user
  
  before_save :validate_card
  before_save :run_auth
  before_destroy :void_auth
  
  attr_accessor :verification_value
  
  CreditCardTypes = [
    ['Visa', 'visa'], 
    ['MasterCard', 'master'], 
    ['Discover', 'discover'], 
    ['American Express', 'american_express']
  ]
  CreditCardHash = CreditCardTypes.inject({}) {|h,e| h[e[0]] = e[1]; h }.invert
  
  
  def cart=(a_cart)
    self[:line_item_collection_id] = a_cart.id
    self.user = a_cart.user
    self.amount = a_cart.total_amount
  end
  
  def creditcard
    @creditcard ||= ActiveMerchant::Billing::CreditCard.new(
      self.attributes.slice("first_name", "last_name", "month", "year", 
        "number").merge("type" => self.card_type, 'verification_value' => self.verification_value)
      )
  end
  
  def address
    self.attributes.slice("address1", "city", "state", "zip", "country").symbolize_keys!
  end
  
  def address=(an_address)
    return if an_address.nil?
    { :street => :address1, :city => :city }.each do |src, dest|
      self.send("#{dest}=", an_address.send(src))  
    end
    self.zip = an_address.postal_code_name
    self.state = an_address.zone_name
    self.country = an_address.country_name
  end
  
  def void_auth
    return if @voided
    response = self.gateway.void(self.transaction_id)
    @voided = response.success?
    logger.debug "Processor response is #{response.inspect}"
    response
  end
  
  def capture
    gateway.capture((self.amount * 100).to_i, self.transaction_id)
  end
  
  protected
  
    def validate_card
      unless self.creditcard.valid?
        self.creditcard.errors.full_messages.each do |err|
          self.errors.add(:base, "Card #{err.downcase}")
        end
        return false
      end
      true
    end
    
    def run_auth
      # to avoid issues with the CC authorizer, last checks on the data submitted are done before requesting CC auth
      unless self.address.nil? || self.line_item_collection_id.nil? || self.user.nil? || self.user.email.nil?
        # if required data is present
        response = self.gateway.authorize((self.amount * 100).to_i,
          self.creditcard, :address => self.address, :order_id => self.line_item_collection_id, :description => CONFIG[:app_name], :customer => self.user_id, :email => self.user.email)
        if response.success?
          logger.debug "Processor response is #{response.inspect}"
          self.transaction_id = response.authorization
          self.number = 'X' * 4 + self.number[-4..-1] rescue 'bogus'
          true
        else
          self.errors.add(:base, response.message)
          false
        end
      else    # if missing any crucial data
        self.errors.add(:base, "something went wrong. try signing out and in again. if still getting this, contact webmaster")
        logger.error("DID NOT RUN AUTH: debug1: address: #{self.address}, line_item_collection_id: #{self.line_item_collection_id}, user: #{self.user}, email: #{self.user ? self.user.email : "NA" }")
        false
      end
    end
    
    def gateway
      @gateway ||= ActiveMerchant::Billing::Base.gateway(:authorize_net).new(
        YAML.load_file(Rails.root.join('config', 'authorizenet.yml')).symbolize_keys
      )
    end
  
end

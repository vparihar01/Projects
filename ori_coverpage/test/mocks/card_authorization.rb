require 'app/models/card_authorization'

class CardAuthorization
  
  protected
  
    def gateway
      @gateway ||= ActiveMerchant::Billing::Base.gateway(:bogus).new
    end
end

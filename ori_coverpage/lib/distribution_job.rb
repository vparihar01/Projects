class DistributionJob < Struct.new(:recipient_id, :options)
  def perform
    recipient = Recipient.find(recipient_id)
    products = recipient.products(options)
    recipient.distribute(products, options[:distribution].merge(:status => options[:status]))
  end
end

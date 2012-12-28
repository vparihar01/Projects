module Admin::RecipientsHelper
  def distribution_link(name, recipient, options = {})
    options.symbolize_keys!
    default_options = {}
    link_to(name, admin_distribution_path('distribution[type]' => recipient.class.to_s, 'distribution[recipient]' => recipient.name, 'product_select' => 'by_season'), default_options.merge(options))
  end
end

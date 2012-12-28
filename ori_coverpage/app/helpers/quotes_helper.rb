module QuotesHelper
  def customer_list
    (admin? ? User : current_user.sales_team.customers).find(
      :all, :order => 'users.name').collect {|c| [ "#{c.name} <#{c.email}>", c.id ] }
  end
end
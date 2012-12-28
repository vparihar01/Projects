class CustomersController < ApplicationController
  before_filter :load_customer, :only => [ :show, :edit, :update, :destroy, :products ]
  before_filter :new_customer, :only => [ :new, :create ]

  def index
    if !params[:q].blank?
      @customers = Customer.simple_search(params, pager)    # issue #134 - instead of @customers = Customer.find_with_ferret(params[:q], :page => params[:page], :per_page => pager)
    else
      @customers = Customer.order('name ASC').paginate( :page => params[:page], :per_page => pager)
    end
  end
  
  def show
    @page_title = "#{@customer.name} - Customers"
  end

  # TODO : investigate the results of this page and make adjustments to the code if neccessary
  def products
    @page_title = "Purchased Products - #{@customer.name} - Customers"
    if params[:reading_level_id].blank? && params[:category_id].blank?
      options = {}
    else
      conditions = []
      conditions << "products.reading_level_id = :reading_level_id" unless params[:reading_level_id].blank?
      conditions << "cp.category_id = :category_id" unless params[:category_id].blank?
      options = { :conditions => [ conditions.join(' and '), 
        { :reading_level_id => params[:reading_level_id], :category_id => params[:category_id] } ] 
      }
    end
    @purchases = @customer.purchased_products(options).group_by {|p| p.name }
  end
  
  protected
  
    def customers
      current_user.admin? ? Customer : current_user.sales_team.customers
    end
    
    def load_customer
      @customer = customers.find(params[:id])
    end
    
    def new_customer
      @customer = Customer.new(params[:customer])
    end
    
    def authorized? 
      return false if current_user.customer?
      current_user.admin? || %w(index show products).include?(self.action_name)
    end
end

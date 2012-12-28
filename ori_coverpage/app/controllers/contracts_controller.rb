class ContractsController < ApplicationController
  before_filter :load_contract, :only => [ :show, :edit, :update, :destroy ]
  before_filter :new_contract, :only => [ :new, :create ]
  before_filter :store_location, :only => [ :new ]
  layout 'sales'
  
  def index
    @contracts = Contract.includes(:sales_team, :sales_zone).order('sales_teams.name ASC').paginate( :page => params[:page], :per_page => pager)
  end
  
  def show
    @page_title = "Contract for #{@contract.sales_team} - #{@contract.sales_zone}"
  end
  
  def new
  end
    
  protected
  
    def load_contract
      @contract = Contract.find(params[:id])
    end
    
    def new_contract
      @contract = Contract.new({:start_on => Time.now.to_date, :rate => '0.25'}.merge(params[:contract]))
    end
    
    # Override the default permissive authorization to allow only admins for most actions
    def authorized?
      return false if current_user.customer?
      current_user.admin? || %w(show).include?(self.action_name)
    end
end

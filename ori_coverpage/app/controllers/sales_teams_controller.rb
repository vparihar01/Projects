class SalesTeamsController < ApplicationController
  before_filter :load_sales_team, :only => [ :show, :edit, :update, :destroy, :commissions, :ytd_sales ]
  before_filter :build_sales_team, :only => [ :new, :create ]
  layout 'sales'
  
  def index
    redirect_to :action => "show" and return unless current_user.admin?
    
    if !params[:q].blank?
      @sales_teams = SalesTeam.where("name like '%#{params[:q]}%' or description like '%#{params[:q]}%' or category like '%#{params[:q]}%'").paginate(:page => params[:page], :per_page => pager)     # issue #134 - iso @sales_teams = SalesTeam.find_with_ferret(params[:q], :page => params[:page], :per_page => pager)
    else
      @sales_teams = SalesTeam.includes(:sales_reps).order('sales_teams.name ASC').paginate(:page => params[:page], :per_page => pager)
    end
  end

  def show
    @page_title = "#{@sales_team.name} - Sales Teams"
  end

  def commissions
    @page_title = "Commissions - #{@sales_team.name} - Sales Teams"
    if (@months = @sales_team.posted_transactions.collect(&:posted_on)).any?
      @month = (Chronic.parse(params[:month]) || @months.first.to_time).beginning_of_month
      @transactions = @sales_team.posted_transactions.where( 'posted_on between ? and ?', @month, @month.end_of_month.end_of_day ).all
    else
      @transactions = []
    end
  end
  
  def ytd_sales
    @page_title = "YTD Sales - #{@sales_team.name} - Sales Teams"
    @current_sales, @previous_sales = @sales_team.ytd_sales
    @sales_goal = @sales_team.current_sales_target
    @sales_total = @sales_team.sales_total(@current_sales)
  end
  
  def create
    respond_to do |format|
      if @sales_team.save
        flash[:notice] = 'Sales team was successfully created.'
        format.html { redirect_to sales_team_url(@sales_team) }
        format.xml  { head :xml => @sales_team, :status => :created, :location => @sales_team }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sales_team.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @sales_team.update_attributes(params[:sales_team])
        flash[:notice] = 'Sales team was successfully updated.'
        format.html { redirect_to sales_team_url(@sales_team) }
        format.xml  { head :created, :location => sales_teams_url }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sales_team.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  protected
  
    def setup_params
      params[:postal_code] ||= {}
      @postal_code = ( PostalCode.find_or_create_by_name_and_zone_id(params[:postal_code][:name], params[:postal_code][:zone_id]) || PostalCode.new(params[:postal_code]) )
      params[:sales_team] ||= {:address_attributes => {}}
      params[:sales_team][:address_attributes][:name] = params[:sales_team][:name]
      params[:sales_team][:address_attributes][:postal_code_id] = @postal_code.try(:id)
    end
    
    def load_sales_team
      setup_params
      @sales_team = current_user.admin? ? SalesTeam.find(params[:id]) : current_user.sales_team
      unless @sales_team.address
        address = @sales_team.build_address(params[:sales_team][:address_attributes])
        address.postal_code = @postal_code
      end
    end

    def build_sales_team
      setup_params
      @sales_team = SalesTeam.new(params[:sales_team])
      address = @sales_team.build_address(params[:sales_team][:address_attributes])
      address.postal_code = @postal_code
    end
    
    # Override the default permissive authorization to allow only admins for most actions
    def authorized?
      return false if current_user.customer?
      current_user.admin? || %w(index show commissions ytd_sales).include?(self.action_name)
    end
end

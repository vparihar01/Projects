class SalesRepsController < ApplicationController
  before_filter :load_team
  before_filter :load_sales_rep, :only => [ :show, :edit, :update, :destroy ]
  layout 'sales'
  
  def index
    @sales_reps = SalesRep.order('name ASC').paginate(:page => params[:page], :per_page => pager)
  end

  def show
    @page_title = "#{@sales_rep.name} - Sales Reps"
  end

  def new
    @sales_rep = SalesRep.new
    @page_title = 'New Sales Rep'
  end
  
  def edit
    @page_title = 'Edit Sales Rep'
  end
  
  def create
    @sales_rep = @sales_team.sales_reps.build(params[:sales_rep])
    respond_to do |format|
      if @sales_rep.save
        flash[:notice] = 'Sales Rep was successfully created.'
        format.html { redirect_to sales_team_sales_rep_path(@sales_team, @sales_rep) }
        format.xml  { head :created, :location => sales_team_sales_rep_path(@sales_team, @sales_rep) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sales_rep.errors.to_xml }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @sales_rep.update_attributes(params[:sales_rep])
        flash[:notice] = 'Sales Rep was successfully updated.'
        format.html { redirect_to sales_team_sales_rep_path(@sales_team, @sales_rep) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sales_rep.errors.to_xml }
      end
    end
  end
  
  def destroy
    @sales_rep.destroy
    redirect_to sales_team_path(@sales_team)
  end
  
  protected
  
    def load_team
      @sales_team = current_user.admin? ?  SalesTeam.find(params[:sales_team_id]) : current_user.sales_team
    end
    
    def load_sales_rep
      @sales_rep = @sales_team.sales_reps.find(params[:id])
    end

    # Override the default permissive authorization to allow only admins for most actions
    def authorized?
      return false if current_user.customer?
      current_user.admin? || ['show'].include?(self.action_name)
    end
end

class Admin::UsersController < AdminController
  before_filter :build_user, :only => [:new, :create]
  before_filter :load_user, :only => [ :show, :edit, :update, :destroy ]
  layout 'admin_users'
  
  def index
    @search = User.search(params[:search])
    @users = @search.paginate(:page => params[:page], :per_page => pager)
  end

  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @user.to_xml }
    end
  end
  
  def new
    # refs #365 -- same type of error, same solution
  end
  
  def create
    respond_to do |format|
      if @user.save
        @user.update_attribute(:type, 'Customer') # TODO: questionable -- set user type automatically to customer
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to admin_users_url }
        format.xml  { head :created, :location => admin_users_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors.to_xml }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to admin_users_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors.to_xml }
      end
    end
  end
  
  def destroy
    @user.destroy
    redirect_to admin_users_url
  end
  
  def export
    @users = User.order("created_at DESC")
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename=users.csv'
    render :layout => false
  end
  
  protected
  
    def build_user
      @user = User.new(params[:user])
    end
    
    def load_user
      @user = User.find(params[:id])
    end
    
end

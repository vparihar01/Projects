class Admin::FormatsController < AdminController
  
  def index
    @formats = Format.all
  end
  
  def show
    @format = Format.find(params[:id])
  end
  
  def new
    @format = Format.new
  end
  
  def create
    @format = Format.new(params[:format])
    if @format.save
      flash[:notice] = "Successfully created format."
      redirect_to admin_formats_url
    else
      render :action => 'new'
    end
  end
  
  def edit
    @format = Format.find(params[:id])
  end
  
  def update
    @format = Format.find(params[:id])
    if @format.update_attributes(params[:format])
      flash[:notice] = "Successfully updated format."
      redirect_to admin_formats_url
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @format = Format.find(params[:id])
    @format.destroy
    flash[:notice] = "Successfully destroyed format."
    redirect_to admin_formats_url
  end
  
  def toggle_default
    @format = Format.find(params[:id])
    @format.toggle!(:is_default)
    redirect_to admin_formats_url
  end
  
  def toggle_pdf
    @format = Format.find(params[:id])
    @format.toggle!(:is_pdf)
    redirect_to admin_formats_url
  end
  
  def toggle_valid
    @format = Format.find(params[:id])
    @format.toggle!(:requires_valid_isbn)
    redirect_to admin_formats_url
  end
end

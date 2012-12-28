class SpecsController < ApplicationController
  before_filter :build_spec, :only => [:new, :create]
  before_filter :load_spec, :only => [:show, :edit, :update, :delete, :destroy]

  def index
    @page_title = "Specifications"
    @specs = current_user.specs
  end

  def show
    @page_title = "Show - Specifications"
    respond_to do |format|
      format.html { redirect_to edit_spec_url(@spec) }
      format.xml  { render :xml => @spec.to_xml }
    end
  end

  def new
    render_new_action
  end

  def create
    respond_to do |format|
      if @spec.save
        flash[:notice] = 'Library Processing Specification was successfully created.'
        format.html { redirect_to redirect_url }
        format.xml  { head :created, :location => specs_url }
      else
        format.html { render_new_action }
        format.xml  { render :xml => @spec.errors.to_xml }
      end
    end
  end

  def edit
    render_edit_action
  end

  def update
    respond_to do |format|
      if @spec.update_attributes(params[:spec])
        flash[:notice] = 'Library Processing Specification was successfully updated.'
        format.html { redirect_to redirect_url }
        format.xml  { head :ok }
      else
        format.html { render_edit_action }
        format.xml  { render :xml => @spec.errors.to_xml }
      end
    end
  end

  def destroy
    @spec.destroy
    respond_to do |format|
      format.html { redirect_to redirect_url }
      format.xml  { head :ok }
    end
  end
  
  protected
    
    def build_spec
      @spec = current_user.specs.build(params[:spec])
    end
  
    def load_spec
      @spec = current_user.specs.find_by_id(params[:id])
      if @spec.nil?  
        flash[:error] = 'Unauthorized.'
        redirect_to specs_url
      end
    end
    
    def redirect_url
      checkout_scope? ? checkout_processing_url : specs_url
    end
    
    def render_new_action
      if checkout_scope?
        @force_tab = ""
        @page_title = "New - Specifications - Checkout"
        render :action => 'new', :layout => 'checkout'
      else
        @page_title = "New - Specifications"
        render :action => 'new'
      end
    end
    
    def render_edit_action
      if checkout_scope?
        @force_tab = ""
        @page_title = "Edit - Specifications - Checkout"
        render :action => 'edit', :layout => 'checkout'
      else
        @page_title = "Edit - Specifications"
        render :action => 'edit'
      end
    end
  
end

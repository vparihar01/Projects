class Admin::SpecsController < AdminController
    before_filter :load_spec, :only => [:show, :edit, :update, :destroy]
    before_filter :build_spec, :only => [:new, :create]

    def index
      @search = Spec.search(params[:search])
      @specs = @search.paginate(:page => params[:page], :per_page => pager)
    end

    def new
      # issue #365 -- if including a blank new, the callbacks are run in proper order whether or not in test mode
    end

    def show
      respond_to do |format|
        format.html
        format.xml  { render :xml => @spec.to_xml }
      end
    end

    def create
      respond_to do |format|
        if @spec.save
          flash[:notice] = 'Spec was successfully created.'
          format.html { redirect_to admin_specs_url }
          format.xml  { head :created, :location => admin_spec_url }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @spec.errors.to_xml }
        end
      end
    end

    def update
      respond_to do |format|
        if @spec.update_attributes(params[:spec])
          flash[:notice] = 'Spec was successfully updated.'
          format.html { redirect_to admin_specs_url }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @spec.errors.to_xml }
        end
      end
    end

    def destroy
      @spec.destroy
      respond_to do |format|
        format.html { redirect_to admin_specs_url }
        format.xml  { head :ok }
      end
    end

    protected

      def build_spec
        @spec = Spec.new(params[:spec])
      end

      def load_spec
        @spec = Spec.find(params[:id])
      end
end

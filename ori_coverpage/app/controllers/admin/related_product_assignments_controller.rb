class Admin::RelatedProductAssignmentsController < AdminController
  before_filter :build_related_product_assignment, :only => [:new, :create]
  before_filter :load_related_product_assignment, :only => [:show, :edit, :update, :destroy]
  
  def index
    @search = RelatedProductAssignment.search(params[:search])
    @related_product_assignments = @search.paginate(:page => params[:page], :per_page => pager)
  end
  
  def new
    # refs #365 -- same type of error, same solution
  end
  
  def create
    respond_to do |format|
      if @related_product_assignment.save
        format.html { 
          flash[:notice] = 'Related product assignment was successfully created.'
          redirect_to admin_related_product_assignment_url(@related_product_assignment)
        }
        format.js { 
          partial = (params[:context] == 'products' ? 'admin/products/related_product_assignment_row' : 'admin/related_products/assignment_row')
          render :update do |page|
            page.insert_html :bottom, 'related_product_assignments', {:partial => partial, :locals => {:assignment => @related_product_assignment}}
            page.visual_effect :highlight, dom_id(@related_product_assignment)
            page[:related_product_assignment_form].reset
          end
        }
      else
        format.html { render :action => 'new' }
        format.js {
          render :update do |page|
             page.alert "Related product assignment was NOT saved, #{@related_product_assignment.errors.full_messages}"
          end
        }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @related_product_assignment.update_attributes(params[:related_product_assignment])
        format.html { 
          flash[:notice] = 'Related product assignment was successfully updated.'
          redirect_to admin_related_product_assignment_url(@related_product_assignment) 
        }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @related_product_assignment.errors.to_xml }
      end
    end
  end

  def destroy
    @related_product_assignment.destroy
    respond_to do |format|
      format.html { 
        flash[:notice] = 'Related product assignment was deleted.'
        redirect_to admin_related_product_assignments_url 
      }
      format.js { 
        render :update do |page|
          page.visual_effect :fade, dom_id(@related_product_assignment), :duration => CONFIG[:fade_duration]
        end
      }
    end
  end
  
  protected
    
    def build_related_product_assignment
      @related_product_assignment = RelatedProductAssignment.new(params[:related_product_assignment])
    end
    
    def load_related_product_assignment
      @related_product_assignment = RelatedProductAssignment.find(params[:id])
    end

end

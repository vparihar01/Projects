class Admin::AssemblyAssignmentsController < AdminController
  before_filter :build_assembly_assignment, :only => [:new, :create]
  before_filter :load_assembly_assignment, :only => [:destroy]
  
  def create
    respond_to do |format|
      if @assembly_assignment.save
        format.html { 
          flash[:notice] = 'Assembly assignment was successfully created.'
          redirect_to admin_product_url(@assembly_assignment.assembly)
        }
        format.js { 
          render :update do |page|
            page.insert_html :bottom, 'assembly_assignments', {:partial => "admin/products/assembly_assignment_row", :locals => {:assignment => @assembly_assignment, :product => @assembly_assignment.title}}
            page.visual_effect :highlight, dom_id(@assembly_assignment)
            page[:assembly_assignment_form].reset
          end
        }
      else
        format.html { 
          flash[:notice] = "Your assembly assignment hasn't been saved, #{@assembly_assignment.errors.full_messages}"
          redirect_to admin_product_url(@assembly_assignment.assembly)
        }
        format.js {
          render :update do |page|
             page.alert "Your assembly assignment hasn't been saved, #{@assembly_assignment.errors.full_messages}"
          end
        }
      end
    end
  end

  def destroy
    @assembly_assignment.destroy
    respond_to do |format|
      format.html { 
        flash[:notice] = 'Assembly assignment was deleted.'
        redirect_to admin_product_url(@assembly_assignment.assembly)
      }
      format.js { 
        render :update do |page|
          page.visual_effect :fade, dom_id(@assembly_assignment), :duration => CONFIG[:fade_duration]
        end
      }
    end
  end
  
  protected
    
    def build_assembly_assignment
      @assembly_assignment = AssemblyAssignment.new(params[:assembly_assignment])
    end
    
    def load_assembly_assignment
      @assembly_assignment = AssemblyAssignment.find(params[:id])
    end
  
end

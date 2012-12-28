class Admin::BisacAssignmentsController < AdminController
  before_filter :build_bisac_assignment, :only => [:new, :create]
  before_filter :load_bisac_assignment, :only => [:destroy]
  
  def create
    logger.debug("# DEBUG: BA create; params")
    params.each do |k,v|
      logger.debug("## '#{k}' => '#{v}'")
    end
    respond_to do |format|
      if @bisac_assignment.save
        format.html { 
          flash[:notice] = 'BISAC assignment was successfully created.'
          redirect_to admin_product_url(@bisac_assignment.product)
        }
        format.js { 
          render :update do |page|
            page.insert_html :bottom, 'bisac_assignments', {:partial => "admin/products/bisac_assignment_row", :locals => {:assignment => @bisac_assignment, :bisac_subject => @bisac_assignment.bisac_subject}}
            page.visual_effect :highlight, dom_id(@bisac_assignment)
            page[:bisac_assignment_form].reset
            page[:bisac_assignment_bisac_subject_id].value = nil
          end
        }
      else
        format.html { 
          flash[:notice] = "Your BISAC assignment hasn't been saved, #{@bisac_assignment.errors.full_messages}"
          redirect_to admin_product_url(@bisac_assignment.product)
        }
        format.js {
          render :update do |page|
             page.alert "Your BISAC assignment hasn't been saved, #{@bisac_assignment.errors.full_messages}"
          end
        }
      end
    end
  end

  def destroy
    @bisac_assignment.destroy
    respond_to do |format|
      format.html { 
        flash[:notice] = 'BISAC assignment was deleted.'
        redirect_to admin_product_url(@bisac_assignment.product)
      }
      format.js { 
        render :update do |page|
          page.visual_effect :fade, dom_id(@bisac_assignment), :duration => CONFIG[:fade_duration]
        end
      }
    end
  end
  
  protected
    
    def build_bisac_assignment
      logger.debug "# DEBUG: BUILD BISAC ASSIGNMENT"
      params[:bisac_assignment].each { |k,v| logger.debug( "# # '#{k}' => '#{v}'")}
      @bisac_assignment = BisacAssignment.new({ :product_id => params[:bisac_assignment][:product_id], :bisac_subject_id => params[:bisac_assignment][:bisac_subject_id]})
    end
    
    def load_bisac_assignment
      logger.debug "# DEBUG: LOAD BISAC ASSIGNMENT #{params[:id]}"
      @bisac_assignment = BisacAssignment.find(params[:id])
    end
  
end

class Admin::ContributorAssignmentsController < AdminController
  before_filter :build_contributor_assignment, :only => [:new, :create]
  before_filter :load_contributor_assignment, :only => [:show, :edit, :update, :destroy]
  
  def index
    @contributor_assignments = ContributorAssignment.includes(:product, :contributor).order("contributors.name ASC").paginate( :page => params[:page], :per_page => pager)
  end
  
  def new
    # refs #365 -- same type of error, same solution
  end
  
  def create
    respond_to do |format|
      if @contributor_assignment.save
        format.html { 
          flash[:notice] = 'Contributor assignment was successfully created.'
          redirect_to admin_contributor_assignment_url(@contributor_assignment)
        }
        format.js { 
          partial = (params[:context] == 'products' ? 'admin/products/contributor_assignment_row' : 'admin/contributors/assignment_row')
          render :update do |page|
            page.insert_html :bottom, 'contributor_assignments', {:partial => partial, :locals => {:assignment => @contributor_assignment}}
            page.visual_effect :highlight, dom_id(@contributor_assignment)
            page[:contributor_assignment_form].reset
          end
        }
      else
        format.html { render :action => 'new' }
        format.js {
          render :update do |page|
             page.alert "Your contributor assignment hasn't been saved, #{@contributor_assignment.errors.full_messages}"
          end
        }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @contributor_assignment.update_attributes(params[:contributor_assignment])
        format.html { 
          flash[:notice] = 'Contributor assignment was successfully updated.'
          redirect_to admin_contributor_assignment_url(@contributor_assignment) 
        }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @contributor_assignment.errors.to_xml }
      end
    end
  end

  def destroy
    @contributor_assignment.destroy
    respond_to do |format|
      format.html { 
        flash[:notice] = 'Contributor assignment was deleted.'
        redirect_to admin_contributor_assignments_url 
      }
      format.js { 
        render :update do |page|
          page.visual_effect :fade, dom_id(@contributor_assignment), :duration => CONFIG[:fade_duration]
        end
      }
    end
  end
  
  protected
    
    def build_contributor_assignment
      @contributor_assignment = ContributorAssignment.new(params[:contributor_assignment])
    end
    
    def load_contributor_assignment
      @contributor_assignment = ContributorAssignment.find(params[:id])
    end
  
end

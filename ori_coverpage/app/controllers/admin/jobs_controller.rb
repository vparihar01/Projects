class Admin::JobsController < AdminController
  before_filter :load_job, :only => [:show, :destroy]

  def index
    if params[:q]
      params[:search] = {}
      params[:search][:name_contains] = params[:q]
    end
    @search = Delayed::Job.search(params[:search])
    @jobs = @search.paginate(:page => params[:page], :per_page => pager)
  end
  
  def show
  end

  def destroy
    respond_to do |format|
      if !@job.nil? && @job.destroy
        format.js {
          render :update do |page|
            page.visual_effect(:fade, dom_id(@job), :duration => CONFIG[:fade_duration])
          end
        }
        format.html {
          flash[:notice] = 'Job was successfully deleted.'
          redirect_to admin_jobs_path
        }
        format.xml  { head :ok }
      else
        msg = 'Job was NOT deleted.'
        format.js {
          render :update do |page|
            page.alert(msg)
          end
        }
        format.html {
          flash[:error] = msg
          redirect_to @job.nil? ? admin_jobs_path : admin_job_url(@job)
        }
        format.xml  { render :xml => msg + (@job.errors), :status => :unprocessable_entity }
      end
    end
  end

  protected

    def load_job
      @job = Delayed::Job.find(params[:id])
    rescue Exception => e
      flash[:error] = "Error finding Job # #{params[:id]}: #{e.message}"
    end
end

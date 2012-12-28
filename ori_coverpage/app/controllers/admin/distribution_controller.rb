class Admin::DistributionController < AdminController
  layout 'admin_distribution'
  before_filter :load_instance_vars

  def index
  end

  def execute
    if params[:distribution].blank? || params[:distribution][:recipient].blank? || params[:distribution][:type].blank?
      flash.now[:error] = "Please complete form"
    elsif !verify_date_params
      # Error message set by verify_date_params
    else
      if recipient = @klass.find_by_name(params[:distribution][:recipient])
        # Get products
        options = params.to_hash.symbolize_keys
        options[:synchronous] ||= ( Rails.env.development? )    # Unless specified, run synchronously in dev mode
        if options[:synchronous]
          products = recipient.products(options)
          result = recipient.distribute(products, options[:distribution].merge(:status => options[:status]))
          result = (result.is_a?(Hash) ? result.values.include?(true) : result)    # Kludge for ImageRecipient results
          flash[:notice] = "Your request has been successfully performed.".html_safe if result
        else
          # Run job in background using DelayedJob
          job = Delayed::Job.enqueue(DistributionJob.new(recipient.id, options))
          result = job ? true : false
          flash[:notice] = "Your request has been <a href=\"#{admin_jobs_path}\">queued</a> as Job ##{job.id}.".html_safe if result
        end
        if result
          redirect_to admin_distribution_url and return
        else
          flash.now[:error] = "Error encountered while performing distribution. Contact #{CONFIG[:webmaster_email]}."
        end
      else
        flash.now[:error] = "Recipient not valid"
      end
    end
    render :action => "index"
  end

  def asset_select
    respond_to do |format|
      format.js {
        render :update do |page|
          page.visual_effect :fade, :asset_select_partial, :duration => CONFIG[:fade_duration]
          page.delay(CONFIG[:fade_duration]*2) do
            if @asset_type && params[:distribution][:override_recipient] == 'true'
              page.replace_html :asset_select_partial, :partial => @asset_type
            else
              page.replace_html :asset_select_partial, nil
            end
            page.replace_html :recipients_partial, :partial => "recipients"
            page.visual_effect :appear, :asset_select_partial, :duration => CONFIG[:fade_duration]
          end
        end
      }
      format.html {
        flash[:notice] = "Selecting #{params[:distribution][:type]}."
        redirect_to admin_distribution_url(:distribution => {:type => params[:distribution][:type]})
      }
    end
  end

  def override_recipient_change
    respond_to do |format|
      format.js {
        render :update do |page|
          page.visual_effect :fade, :asset_select_partial, :duration => CONFIG[:fade_duration]
          page.delay(CONFIG[:fade_duration]*2) do
            if params[:distribution][:override_recipient] == 'true'
              page.replace_html :asset_select_partial, :partial => @asset_type
            else
              page.replace_html :asset_select_partial, nil
            end
            page.visual_effect :appear, :asset_select_partial, :duration => CONFIG[:fade_duration]
          end
        end
      }
      format.html {
        flash[:notice] = "Selecting #{params[:distribution][:type]}."
        redirect_to admin_distribution_url(:distribution => {:type => params[:distribution][:type]})
      }
    end
  end

  protected

  def load_instance_vars
    # Default params
    params[:distribution] ||= {}
    params[:distribution][:type] ||= Recipient::SUBCLASSES.first
    # Test params
    begin
      throw unless Recipient::SUBCLASSES.include?(params[:distribution][:type])
      @klass = params[:distribution][:type].classify.constantize
      @asset_type = params[:distribution][:type].sub(/Recipient$/, '').downcase
    rescue
      @klass = nil
      @asset_type = nil
    end
  end

end

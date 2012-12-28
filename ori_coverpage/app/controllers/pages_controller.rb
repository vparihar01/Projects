class PagesController < ApplicationController
  before_filter :allow_only_html_requests
  skip_before_filter :login_required
  before_filter :set_page_title, :only => [:home, :geolocation, :contact, :subscribe, :unsubscribe]
  ssl_required :hosted_ebooks_trial

  def view
    raise PageNotFound unless @page = Page.find_by_path(params[:path])
    # protect pages using admin layout
    if @page.layout == 'admin' && !admin?
      redirect_to root_path
    else
      @page_title = @page.title
      render :layout => (@page.layout.blank? ? CONFIG[:controller_layouts][:pages_controller] : @page.layout)
    end
  end
  
  def show
    @page = Page.find(params[:id])
    render :action => 'view'
  end

  # Complex pages, not stored in pages table
  # NB: 
  # - must create named route in config/routes.rb for each action below
  # - use config.yml to specify which layout to render
  
  def home
    render :layout => set_page_layout
  end
  
  def geolocation
    @page_title = 'Location'
    render :layout => set_page_layout
  end

  def contact
    if request.post?
      @form = Contact.new(params[:form])
      if mini_captcha_valid?(@form)
          NotificationMailer.contact_form(@form).deliver
          flash[:notice] = 'Your message was successfully delivered.'
          redirect_to public_page_path(:help) and return
      end
    else
      @form = Contact.new
      if !logged_in?
        @form.email = nil
        @form.name = nil
      else
        @form.email = current_user.email
        @form.name = current_user.name
      end
    end
    render :layout => set_page_layout
  end
  
  def hosted_ebooks_trial
    if request.post?
      @form = HostedEbooksTrial.new(params[:form])
      if @form.valid?
        NotificationMailer.hosted_ebooks_trial_form(@form).deliver
        flash[:notice] = 'Your request was successfully delivered.'
        redirect_to public_page_path(:help) and return
      end
    else
      @form = HostedEbooksTrial.new
      if !logged_in?
        @form.email = nil
        @form.name = nil
      else
        @form.email = current_user.email
        @form.name = current_user.name
      end
    end
    render :layout => set_page_layout
  end
  
  def subscribe
    unless CONFIG[:subscribe_url].blank?
      render :layout => set_page_layout
    else
      flash[:error] = 'Newsletter subscribe functionality is not enabled.'
      redirect_to root_path
    end
  end
  
  def unsubscribe
    unless CONFIG[:unsubscribe_url].blank?
      render :layout => set_page_layout
    else
      flash[:error] = 'Newsletter unsubscribe functionality is not enabled.'
      redirect_to root_path
    end
  end
  
  def reps
    @postal_code = PostalCode.find_by_name(params[:postal_code])
    if @postal_code
      @contracts = @postal_code.try(:sales_zone).try(:contracts)
    end
    render :layout => set_page_layout
  end

  protected

    def set_page_title
      @page_title = action_name.humanize.titleize
    end

    def set_page_layout
      CONFIG[:page_layouts].has_key?(self.action_name) ? CONFIG[:page_layouts][self.action_name] : CONFIG[:controller_layouts][:pages_controller]
    end

end

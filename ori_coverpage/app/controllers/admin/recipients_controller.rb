class Admin::RecipientsController < AdminController
  layout 'admin_recipients'
  before_filter :fix_params, :only => [:create, :update]
  #include AdminModelControllerMethods
  
  def index
    @search = Recipient.search(params[:search])
    @recipients = @search.paginate(:page => params[:page], :per_page => pager)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @recipients }
    end
  end

  def show
    @recipient = Recipient.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @recipient }
    end
  end

  def new
    @recipient = DataRecipient.new # set default recipient type as DataRecipient
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @recipient }
    end
  end

  def select_type
    respond_to do |format|
      if Recipient::SUBCLASSES.include?(params[:type])
        @recipient = params[:type].classify.constantize.new
        format.js {
          render :update do |page|
            page.visual_effect :fade, :preferences, :duration => CONFIG[:fade_duration]
            page.delay(CONFIG[:fade_duration]*2) do
              page.replace_html 'preferences', :partial => "#{params[:type].underscore}_preferences"
              page.visual_effect :appear, :preferences, :duration => CONFIG[:fade_duration]
            end
          end
        }
        format.html {
          flash[:notice] = "Creating #{params[:type]}."
          redirect_to new_admin_recipient_url(@recipient)
        }
      else
        msg = "Unacceptable recipient type"
        format.js {
          render :update do |page|
            page.visual_effect :fade, :preferences, :duration => CONFIG[:fade_duration]
            page.delay(CONFIG[:fade_duration]*2) do
              page.replace_html 'preferences', :partial => "recipient_preferences"
              page.visual_effect :appear, :preferences, :duration => CONFIG[:fade_duration]
            end
          end
        }
        format.html {
          flash[:error] = msg
          redirect_to new_admin_recipient_url
        }
      end
    end
  end

  def edit
    @recipient = Recipient.find(params[:id])
  end

  def create
    if !params[:recipient].nil? && Recipient::SUBCLASSES.include?(params[:recipient][:type])
      type = params[:recipient].delete(:type) # to avoid warning on mass assigning this attribute
      @recipient = type.constantize.new(params[:recipient])
    else
      @recipient = Recipient.new(params[:recipient])
    end

    respond_to do |format|
      if @recipient.save
        format.html { redirect_to(admin_recipients_url, :notice => 'Recipient was successfully created.') }
        format.xml  { render :xml => @recipient, :status => :created, :location => @recipient }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @recipient.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @recipient = Recipient.find(params[:id])
    
    respond_to do |format|
      if @recipient.update_attributes(params[:recipient])
        format.html { redirect_to(admin_recipients_url, :notice => 'Recipient was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @recipient.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @recipient = Recipient.find(params[:id])
    @recipient.destroy

    respond_to do |format|
      format.html { redirect_to(admin_recipients_url) }
      format.xml  { head :ok }
    end
  end
  
  protected
  
  def fix_params
    # Change array to yaml string because preferences gem doesn't support arrays
    # Can't perform this change in model with before_save hook because preferences gem acts beforehand
    if params[:recipient][:preferred_data_format_ids].is_a?(Array)
      params[:recipient][:preferred_data_format_ids] = params[:recipient][:preferred_data_format_ids].to_yaml
    end
    if params[:recipient][:preferred_image_types].is_a?(Array)
      params[:recipient][:preferred_image_types] = params[:recipient][:preferred_image_types].to_yaml
    end
    if params[:recipient][:preferred_image_formats].is_a?(Array)
      params[:recipient][:preferred_image_formats] = params[:recipient][:preferred_image_formats].to_yaml
    end
  end
end

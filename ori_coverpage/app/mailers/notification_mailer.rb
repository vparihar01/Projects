class NotificationMailer < ActionMailer::Base
  helper :mailers
  
  default :from => CONFIG[:webmaster_email],
          :to => CONFIG[:webmaster_email]
  
  def catalog_requests
    file_path = Rails.root.join("protected", "catalog_requests.csv")
    attachments[File.basename(file_path)] = File.read(file_path)
    mail( :to => [CONFIG[:webmaster_email], CONFIG[:support_email]],
          :subject => "#{CONFIG[:app_name]}: Catalog Requests" ) do |format|
            format.text { render :action => 'attachment' }
    end
  end
  
  def contact_form(form)
    @name = form.name
    @email = form.email
    @comments = form.comments
    @subscribe = form.subscribe
    
    mail( :from => form.email,
          :reply_to => form.email,
          :to => [CONFIG[:webmaster_email], CONFIG[:support_email]],
          :subject => "#{CONFIG[:app_name]}: Contact Form" )
  end
  
  def hosted_ebooks_trial_form(form)
    @form = form
    
    mail( :from => form.email,
          :reply_to => form.email,
          :to => (CONFIG[:hosted_ebooks_trial_email].is_a?(Array) ? CONFIG[:hosted_ebooks_trial_email] : Array(CONFIG[:hosted_ebooks_trial_email])) << CONFIG[:webmaster_email],
          :subject => "#{CONFIG[:app_name]}: Hosted Ebooks Trial Request" )
  end
  
  def forgot_password(user, password)
    @name = user.name
    @password = password
    
    mail( :from => CONFIG[:webmaster_email],
          :to => user.email_with_name,
          :bcc => CONFIG[:webmaster_email],
          :subject => "#{CONFIG[:app_name]}: Forgotten password notification" )
  end
  
  def sale_change(sale, new_status)
    @sale = Sale.find(sale).reload
    @sale_date = @sale.completed_at
    @old_status = @sale.status
    @new_status = new_status
    mail( :from => CONFIG[:sales_email],
          :to => @sale.user.email_with_name,
          :bcc => CONFIG[:webmaster_email],
          :subject => "#{CONFIG[:app_name]}: Order Update" )
  end
  
  def data_delivered(recipients, *args)
    # Options: file_path, content_type, subject, message, server
    options = args.extract_options!.symbolize_keys
    unless options[:file_path].blank?
      unless File.exist?(options[:file_path])
        Rails.logger.error("! Error: File attachment not found '#{options[:file_path]}'")
        return false
      end
      @message = options[:message] || "Please find attached product data from #{CONFIG[:app_name]}."
      content_type = options[:content_type] || "text/#{File.extname(options[:file_path]).sub('.','')}"
      attachments[File.basename(options[:file_path])] = File.read(options[:file_path])
    else
      @message = options[:message] || "Product data from #{CONFIG[:app_name]} has been uploaded to your designated server."
      content_type = nil
    end
    @server = options[:server]
    @is_csv = (content_type == 'text/csv')
    mail( :from => CONFIG[:onix_email],
          :to => recipients,
          :bcc => CONFIG[:webmaster_email],
          :subject => "#{CONFIG[:app_name]}: #{options[:subject] || "Product data"}" )
  end

  def images_delivered(recipient, *args)
    # Options: subject, server
    options = args.extract_options!.symbolize_keys
    @server = options[:server]
    mail( :from => CONFIG[:image_email],
          :to => recipient,
          :bcc => CONFIG[:webmaster_email],
          :subject => "#{CONFIG[:app_name]}: #{options[:subject] || "Images delivered"}" )
  end
  
  def images_available(recipient, subject = nil)
    mail( :from => CONFIG[:image_email],
          :to => recipient,
          :bcc => CONFIG[:webmaster_email],
          :subject => (subject || "#{CONFIG[:app_name]}: Images available") )
  end

  def ebooks_delivered(recipients, *args)
    # Options: file_path, subject, server
    options = args.extract_options!.symbolize_keys
    @server = options[:server]
    @has_attachment = !options[:file_path].blank?
    attachments[File.basename(options[:file_path])] = File.read(options[:file_path]) unless options[:file_path].blank?
    mail( :from => CONFIG[:onix_email],
          :to => recipients,
          :bcc => CONFIG[:webmaster_email],
          :subject => "#{CONFIG[:app_name]}: #{options[:subject] || "Ebooks delivered"}" )
  end
  
  def line_items
    file_path = Rails.root.join("protected", "line_items.csv")
    attachments[File.basename(file_path)] = File.read(file_path)
    mail( :to => [CONFIG[:webmaster_email], CONFIG[:support_email]],
          :subject => "#{CONFIG[:app_name]}: Line Items" ) do |format|
            format.text { render :action => 'attachment' }
    end
  end
  
  def order(user, sale)
    @user = user
    @sale = sale
    
    mail( :from => CONFIG[:support_email],
          :to => [user.email_with_name, CONFIG[:webmaster_email], CONFIG[:support_email]],
          :subject => "#{CONFIG[:app_name]}: Order Confirmation" )
  end
  
  def orders
    file_path = Rails.root.join("protected", "orders.csv")
    attachments[File.basename(file_path)] = File.read(file_path)
    mail( :to => [CONFIG[:webmaster_email], CONFIG[:support_email]],
          :subject => "#{CONFIG[:app_name]}: Orders" ) do |format|
            format.text { render :action => 'attachment' }
    end
  end
  
  def product(tell_a_friend, user, product)
    recipients = [CONFIG[:webmaster_email], tell_a_friend[:email]]
    recipients << user.email_with_name if tell_a_friend[:cc].to_i == 1
    
    @user = user
    @product = product
    @message = tell_a_friend[:message]
    
    mail( :from => CONFIG[:support_email],
          :to => recipients,
          :subject => "#{CONFIG[:app_name]}: Tell A Friend" )
  end
  
  def specs
    file_path = Rails.root.join("protected", "specs.csv")
    attachments[File.basename(file_path)] = File.read(file_path)
    mail( :to => [CONFIG[:webmaster_email], CONFIG[:support_email]],
          :subject => "#{CONFIG[:app_name]}: Specs" ) do |format|
            format.text { render :action => 'attachment' }
    end
  end

end

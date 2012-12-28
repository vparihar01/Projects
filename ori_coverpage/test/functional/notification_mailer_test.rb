require File.dirname(__FILE__) + '/../test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  require File.dirname(__FILE__) + '/../../app/mailers/notification_mailer'
  
  test "forgot_password_email" do
    user = users(:quentin)

    email = NotificationMailer.forgot_password(user, 'newpass').deliver
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal  ["#{user.email_with_name}"], email[:to].formatted
    assert_equal  ["#{user.email}"], email.to
    assert_equal  [CONFIG[:webmaster_email]], email.bcc

    assert_equal "#{CONFIG[:app_name]}: Forgotten password notification", email.subject
    assert_match /At your request, #{CONFIG[:app_name]} has reset your password./, email.encoded
    assert_match /New password: newpass/, email.encoded
  end

  test "order_email" do
    @user = users(:quentin)
    assert @user
    @sale = line_item_collections(:paid_sale)
    @sale.completed_at = Time.now()
    assert @sale

    email = NotificationMailer.order(@user, @sale).deliver
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [@user.email, CONFIG[:webmaster_email], CONFIG[:support_email]], email.to

    assert_equal "#{CONFIG[:app_name]}: Order Confirmation", email.subject
    assert_match /Thank you for shopping/, email.encoded
    assert_match /Order Number: #{@sale.id}/, email.encoded
  end

  test "contact_form_email" do
    @user = users(:quentin)
    assert @user

    @form = Contact.new(:name => "someone", :comments =>"test", :email =>"srejbi@mobility.ws")

    email = NotificationMailer.contact_form(@form).deliver
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [CONFIG[:webmaster_email], CONFIG[:support_email]], email.to

    assert_equal "#{CONFIG[:app_name]}: Contact Form", email.subject
    assert_match /#{@form.name}/, email.encoded
    assert_match /#{@form.comments}/, email.encoded
  end

  test "data_delivered_email" do
    @user = users(:quentin)
    assert @user

    emails = ["test@mobility.ws", "test@test.com"]
    file_path = Rails.root.join("test/fixtures/files/products.txt")
    subject = "test file"
    message = "here you go"

    email = NotificationMailer.data_delivered(emails, :file_path => file_path, :subject => subject, :message => message).deliver
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [CONFIG[:webmaster_email]], email.bcc
    assert_equal emails, email.to
    assert_match /#{subject}/, email.subject
    assert_match /#{message}/, email.encoded
    assert_equal email.attachments[0].filename, File.basename(file_path)
  end
  
  test "images_delivered_email" do
    emails = ["test@test.com"]
    subject = "test file"
    server = Uploader.new("ftp://user:password@test.com/path/to/folder")
    email = NotificationMailer.images_delivered(emails, :subject => subject, :server => server).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [CONFIG[:webmaster_email]], email.bcc
    assert_equal emails, email.to
    assert_match /#{subject}/, email.subject
    assert_match /uploaded to your designated server/, email.encoded
    assert_match /Host: #{server.host}/, email.encoded
    assert_equal email.attachments.count, 0
  end
  
  test "ebooks_delivered_email" do
    emails = ["test@test.com"]
    file_path = Rails.root.join("test/fixtures/files/products.txt")
    subject = "test file"
    server = Uploader.new("ftp://user:password@test.com/path/to/folder")
    email = NotificationMailer.ebooks_delivered(emails, :file_path => file_path, :subject => subject, :server => server).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [CONFIG[:webmaster_email]], email.bcc
    assert_equal emails, email.to
    assert_match /#{subject}/, email.subject
    assert_match /uploaded to your designated server/, email.encoded
    assert_match /Host:/, email.encoded
    assert_equal email.attachments.count, 1
    assert_equal email.attachments[0].filename, File.basename(file_path)
  end
  
  test "product_email" do
    current_user = users(:dallas_schools)
    assert current_user
    @product = Product.first
    assert @product

    @form = Email.new( :email => 'test@mobility.ws', :message => 'just checking out', :cc => true )

    email = NotificationMailer.product(@form, current_user, @product).deliver
    assert !ActionMailer::Base.deliveries.empty?

    assert_equal [CONFIG[:webmaster_email], 'test@mobility.ws', current_user.email], email.to
    
    assert_equal "#{CONFIG[:app_name]}: Tell A Friend", email.subject
    assert_match /To view the product "#{@product.name}",/, email.encoded
    assert_match /#{@form.message}/, email.encoded
  end

end

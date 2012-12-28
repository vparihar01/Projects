require File.dirname(__FILE__) + '/../../test_helper'

class Admin::DistributionControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  
  def setup
    CONFIG[:image_archive_dir] = Rails.root.join("test/fixtures/files")
    @controller = Admin::DistributionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user       = login_as :admin
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_template 'index'
  end

  # when user changes distribution type dropdown
  test "should asset_select JS" do
    Recipient::SUBCLASSES.each do |distribution_type|
      @request.accept = 'application/javascript'
      get :asset_select, :distribution => {:type => distribution_type}
      assert_response :success
      # TODO verify page updates
    end

    get :asset_select, :distribution => {:type => 'INVALID'}
    assert_response :success
    # TODO verify page updates
  end

  test "should asset_select HTML" do
    Recipient::SUBCLASSES.each do |distribution_type|
      get :asset_select, :distribution => {:type => distribution_type}
      assert_response :redirect
      assert_redirected_to admin_distribution_path(:distribution => {:type => distribution_type})
    end

    get :asset_select, :distribution => {:type => 'INVALID'}
    assert_response :redirect
    assert_redirected_to admin_distribution_path(:distribution => {:type => 'INVALID'})
  end

  test "should distribute data" do
    DataRecipient.all.each do |recipient|
      assert_difference Delayed::Job, :count do
        post :execute, :distribution => { :type => 'DataRecipient', :recipient => recipient.name }
        assert_redirected_to admin_distribution_url
        assert_match /Your request has been/, flash[:notice]
      end
    end
  end

  test "should distribute select data" do
    # TODO add more tests with select dates...
    isbns = 'old, recent'

    DataRecipient.all.each do |recipient|
      assert_difference Delayed::Job, :count do
        post :execute, :distribution => { :type => 'DataRecipient', :recipient => recipient.name, :product_select => 'by_isbn', :isbns => isbns }
        assert_redirected_to admin_distribution_url
        assert_match /Your request has been/, flash[:notice]
      end
    end
  end

  test "should distribute ebooks" do
    EbookRecipient.all.each do |recipient|
      assert_difference Delayed::Job, :count do
        post :execute, :distribution => { :type => 'EbookRecipient', :recipient => recipient.name, :force => true, :clean => true }
        assert_redirected_to admin_distribution_url
        assert_match /Your request has been/, flash[:notice]
      end
    end
  end

  test "should distribute select ebooks" do
    # TODO add more tests with select dates...
    isbns = 'old, recent'

    EbookRecipient.all.each do |recipient|
      assert_difference Delayed::Job, :count do
        post :execute, :distribution => { :type => 'EbookRecipient', :recipient => recipient.name, :force => true, :clean => true, :product_select => 'by_isbn', :isbns => isbns }
        assert_redirected_to admin_distribution_url
        assert_match /Your request has been/, flash[:notice]
      end
    end
  end

  test "should distribute images" do
    ImageRecipient.all.each do |recipient|
      assert_difference Delayed::Job, :count do
        post :execute, :distribution => { :type => 'ImageRecipient', :source => 'upcoming', :recipient => recipient.name }
        assert_redirected_to admin_distribution_url
        assert_match /Your request has been/, flash[:notice]
      end
    end
  end

  test "should create job when image distribution called" do
    # TODO add more tests with select dates...
    isbns = 'old, recent'

    ImageRecipient.all.each do |recipient|
      assert_difference Delayed::Job, :count do
        post :execute, :distribution => { :type => 'ImageRecipient', :recipient => recipient.name, :force => true, :clean => true, :product_select => 'by_isbn', :isbns => isbns }
        assert_redirected_to admin_distribution_url
        assert_match /Your request has been/, flash[:notice]
      end
    end
  end

  test "should distribute select images when called synchronously" do
    # TODO add more tests with select dates...
    isbns = 'old, recent'

    ImageRecipient.all.each do |recipient|
      post :execute, :distribution => { :type => 'ImageRecipient', :recipient => recipient.name, :force => true, :clean => true, :product_select => 'by_isbn', :isbns => isbns }
      assert_redirected_to admin_distribution_url
      assert_match /Your request has been/, flash[:notice]
    end
  end
end

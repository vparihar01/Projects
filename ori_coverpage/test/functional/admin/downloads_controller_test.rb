require File.dirname(__FILE__) + '/../../test_helper'

class Admin::DownloadsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :downloads, :tags, :taggings

  def setup
    @controller = Admin::DownloadsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:downloads)
    assert_equal Download.all, assigns(:downloads)
  end

  test "should_search_downloads_by_title" do
    get :index, :search => { :title_like => 'test'}
    assert_response :success
    assert_not_nil assigns(:downloads)
    assert_equal Download.where("title like '%test%'").all, assigns(:downloads)
    assert_template 'index'
  end

  test "should_edit_download" do
    download = downloads(:one)
    get :edit, :id => download.id
    assert_response :success
    assert_template 'edit'
  end

  test "should_show_download" do
    download = downloads(:one)
    get :show, :id => download.id
    assert_response :success
    assert_not_nil assigns(:download)
    assert_template 'show'
  end

  test "should_show_error_message_on_invalid_download" do
    get :show, :id => Download.last.id + 1
    assert_response :redirect
    assert_redirected_to admin_downloads_url
    assert_nil assigns(:download)
    assert_equal "Unknown ID", flash[:error]
  end

  test "should_update_download_title" do
    download = downloads(:one)
    post :update, :id => download.id, :download => { :title => download.title.concat(" UPDATED") }
    assert_redirected_to admin_downloads_url
    assert_equal 'Download was successfully updated.', flash[:notice]
  end

  test "should_not_update_download_with_errors" do
    download = downloads(:one)
    post :update, :id => download.id, :download => { :title => "" }
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:download)
    assert assigns(:download).errors.collect { |field,error| "#{field} #{error}" }.include?("title can't be blank")
    assert_not_equal download.reload.title, assigns(:download).title
    assert_not_equal 'Download was successfully updated.', flash[:notice]
  end


  test "should_check_new_download_form" do
    get :new
    assert_response :success
    assert_not_nil assigns(:download)
    assert_template 'new'
  end

  test "should_create_new_download" do
    assert_difference Download, :count do
      post :create, :download => valid_download
      assert_not_nil assigns(:download)
      assert_redirected_to admin_downloads_url
      assert_equal 'Download was successfully created.', flash[:notice]
    end
  end

  test "should_not_create_new_download_with_errors" do
    assert_difference Download, :count, 0 do
      post :create, :download => { :title => "", :description => 'erroneous review -- without title' }
      assert_response :success
      assert_template 'new'
      assert_not_nil assigns(:download)
      assert assigns(:download).errors.collect { |field,error| "#{field} #{error}" }.include?("title can't be blank")
      assert_not_equal 'Download was successfully created.', flash[:notice]
    end
  end

  test "should_destroy_download" do
    assert_difference Download, :count, -1 do
      delete :destroy, :id => downloads(:one)
      assert_redirected_to admin_downloads_url
      assert_equal 'Download was successfully deleted.', flash[:notice]
    end
  end

  test "should_test_visiblity_toggling" do
    @request.accept = 'application/javascript'
    put :toggle, :id => downloads(:one).to_param
    assert_response :success
    assert_not_nil assigns(:download)

    @request.accept = 'application/xml'
    put :toggle, :id => downloads(:one).to_param
    assert_response :success
    assert_not_nil assigns(:download)

    @request.accept = 'text/html'
    put :toggle, :id => downloads(:one).to_param
    assert_response :redirect
    assert_not_nil assigns(:download)
    assert_redirected_to admin_download_url(assigns(:download))

    #TODO: write test cases that test failed toggle -- if can not, that branch is dead code in the controller
  end

end

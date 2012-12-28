require File.dirname(__FILE__) + '/../../test_helper'

class Admin::FaqsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :faqs, :tags, :taggings
  
  def setup
    @controller = Admin::FaqsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:faqs)
  end

  test "should_get_new" do
    get :new
    assert_response :success
  end

  test "should_create_faq" do
    assert_difference( Faq, :count ) do
      post :create, :faq => {"tag_list"=>"test", "question"=>"How can I test FAQ's?", "answer"=>"go ahead and test all possibilities"}
    end

    assert_redirected_to admin_faqs_path
    assert_equal 'Faq was successfully created.', flash[:notice]
  end

  test "should_not_create_invalid_faq" do
    assert_difference( Faq, :count, 0 ) do
      post :create, :faq => {"tag_list"=>"test", "question"=>"How can I test FAQ's?", "answer"=> nil}
      assert_response :success
      assert_template 'new'
    end
  end

  test "should_show_faq" do
    get :show, :id => faqs(:one).to_param
    assert_response :success
  end

  test "should_get_edit" do
    get :edit, :id => faqs(:one).to_param
    assert_response :success
  end

  test "should_update_faq" do
    put :update, :id => faqs(:one).to_param, :faq => { "tag_list"=>"TAG", "question"=>"QUESTION", "answer"=>"ANSWER" }
    assert_redirected_to admin_faqs_path
    assert_equal 'Faq was successfully updated.', flash[:notice]
  end

  test "should_fail_tp_update_invalid_faq" do
    put :update, :id => faqs(:one).to_param, :faq => { "tag_list"=>"TAG", "question"=>"QUESTION", "answer"=>nil }
    assert_response :success
    assert_template 'edit'
  end

  test "should_destroy_faq" do
    faq = Faq.first
    delete :destroy, :id => faq
    assert_redirected_to admin_faqs_url
    assert !Faq.exists?(faq.id)
  end

  test "should_create_and_destroy_tags_properly" do
    assert_difference( Tagging, :count ) do
      # create a faq with 2 tags, then delete one of the tags by updating the faq
      assert_difference( Tagging, :count, 2 ) do
        assert_difference( Tag, :count, 2 ) do
          assert_difference( Faq, :count ) do
            post :create, :faq => valid_faq( 'tag_list' => 'valid tag one, valid tag two' )
          end
        end
      end
      # one tagging should be removed when tag removed from faq
      assert_difference( Tagging, :count, -1 ) do
        # but the tag record itself (removed tag) should remain in the tags table
        assert_no_difference( Tag, :count ) do
          # faq record should not be removed, of course
          assert_no_difference( Faq, :count ) do
            post :update, :id => Faq.last.id, :faq => valid_faq( 'tag_list' => 'valid tag two' )
          end
        end
      end
    end
  end

end

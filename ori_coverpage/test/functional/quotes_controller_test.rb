require File.dirname(__FILE__) + '/../test_helper'
#require 'quotes_controller'

# Re-raise errors caught by the controller.
#class QuotesController; def rescue_action(e) raise e end; end

class QuotesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :line_item_collections, :line_items, :sales_teams, :products, :product_formats, :formats
  
  def setup
    @controller = QuotesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  test "list_all_quotes_as_admin" do
    user = login_as :admin
    assert user.is_a?(Admin)
    get :index
    assert_equal Quote.order('name').all, assigns(:quotes)
  end
  
  test "list_only_own_quotes_as_sales_rep" do
    login_as :aaron
    get :index
    assert_equal users(:aaron).quotes.order('name').all, assigns(:quotes)
  end
  
  test "list_all_sales_team_quotes_for_head_sales_rep" do
    login_as :quentin
    get :index
    assert_equal SalesTeam.find(1).quotes.order('name').all, assigns(:quotes)
  end
  
  test "show_any_quote_as_admin" do
    @quote = Quote.first
    login_as :admin
    [:show, :edit].each do |action|
      get action, :id => @quote.id
      assert_equal @quote, assigns(:quote)
    end
  end
  
  test "show_own_quote_as_sales_rep" do
    @quote = users(:aaron).quotes.first
    login_as :aaron
    [:show, :edit].each do |action|
      get action, :id => @quote.id
      assert_equal @quote, assigns(:quote)
    end
  end
  
  test "show_any_team_quote_as_head_sales_rep" do
    @quote = users(:aaron).quotes.first
    login_as :quentin
    [:show, :edit].each do |action|
      get action, :id => @quote.id
      assert_equal @quote, assigns(:quote)
    end    
  end
  
  test "hide_other_user_quotes_from_sales_rep" do
    @quote = Quote.first
    user = login_as :aaron
    assert !user.quotes.include?(@quote)
    [:show, :edit].each do |action|
      assert_raise(ActiveRecord::RecordNotFound) { get action, :id => @quote.id }
    end
  end
  
  test "hide_other_team_quotes_from_head_sales_rep" do
    @quote = line_item_collections(:quote_3) # sales_team_id = 2
    user = login_as :quentin # manager of sales_team_id = 1
    assert !user.sales_team.quotes.include?(@quote)
    [:show, :edit].each do |action|
      assert_raise(ActiveRecord::RecordNotFound) { get action, :id => @quote.id }
    end
  end
  
  test "destroy_any_quote_as_admin" do
    @quote = Quote.first
    login_as :admin
    assert_difference Quote, :count, -1 do
      delete :destroy, :id => @quote.id
    end
    assert_redirected_to :action => "index"
    assert_equal "The quote has been deleted.", flash[:notice]
  end
  
  test "destroy_own_quote_as_sales_rep" do
    @quote = users(:aaron).quotes.first
    login_as :aaron
    assert_difference Quote, :count, -1 do
      delete :destroy, :id => @quote.id
      assert_equal @quote, assigns(:quote)
    end
  end
  
  test "destroy_any_team_quote_as_head_sales_rep" do
    @quote = users(:aaron).quotes.first
    login_as :quentin
    assert_difference Quote, :count, -1 do
      delete :destroy, :id => @quote.id
      assert_equal @quote, assigns(:quote)
    end    
  end
  
  test "prevent_destruction_of_other_user_quotes_from_sales_rep" do
    @quote = Quote.first
    user = login_as :aaron
    assert !user.quotes.include?(@quote)
    assert_no_difference Quote, :count do
      assert_raise(ActiveRecord::RecordNotFound) { delete :destroy, :id => @quote.id }
    end
  end
  
  test "hide_other_team_quotes_from_head_sales_rep_on_delete" do
    @quote = line_item_collections(:quote_3)
    user = login_as :quentin
    assert !user.sales_team.quotes.include?(@quote)
    assert_no_difference Quote, :count do
      assert_raise(ActiveRecord::RecordNotFound) { delete :destroy, :id => @quote.id }
    end
  end

  test "preserve_cart_items_when_setting_up_new_quote" do
    create_cart(user = login_as(:admin))
    assert_no_difference @cart.line_items, :count do
      get :new
    end
    assert_response :success
    assert_equal assigns(:quote).line_items[0].line_item_collection_id, @cart.line_items[0].line_item_collection_id
    assert_equal assigns(:quote).line_items[0].total_amount, @cart.line_items[0].total_amount
  end
  
  test "creating_quote_with_line_items" do
    user = login_as(:admin)
    assert_difference Quote, :count, +1 do
      assert_difference LineItem, :count, valid_quote_with_lines["line_items_attributes"].size do
        post :create, :quote => valid_quote_with_lines
      end
    end
    assert_redirected_to :action => "index"
    assert_equal user, Quote.find(:last).user
    assert_equal Quote.last.id, LineItem.last.line_item_collection_id
  end
  
  test "assign_user_when_creating_quote" do
    create_cart(user = login_as(:admin))
    assert_difference Quote, :count do
      post :create, :quote => valid_quote #('user_id' => user.id)
    end
    assert_redirected_to :action => "index"
    assert_equal "The quote has been created.", flash[:notice]
    assert_equal user, Quote.find(:last).user
  end

  test "verify_assignment_of_other_user_when_creating_quote_as_admin" do
    create_cart(user = login_as(:admin))
    assert_difference Quote, :count do
      post :create, :quote => valid_quote('user_id' => users(:aaron).id)
    end
    assert_equal users(:aaron), Quote.find(:last).user
  end
  
  test "prevent_assignment_of_other_user_when_creating_quote_and_not_admin" do
    create_cart(user = login_as(:quentin))
    assert_difference Quote, :count do
      post :create, :quote => valid_quote('user_id' => users(:aaron).id)
    end
    assert_equal user, Quote.find(:last).user
  end
  
  test "copy_quote_to_quote" do
    user = login_as :aaron
    @quote = user.quotes.first
    assert_difference Quote, :count do
      post :copy, :id => @quote.id
    end
    @new_quote = Quote.find(:last)
    assert_redirected_to :action => "edit", :id => @new_quote.id
    assert_equal "Copy of #{@quote.name}", @new_quote.name

    #follow_redirect
    assert_equal @new_quote, assigns(:new_quote)
  end
  
  test "copy_quote_to_cart" do
    assert_not_nil @cart = (user = login_as(:quentin)).cart
    @quote = user.quotes.first
    assert @quote.line_items.any?
    assert_no_difference Cart, :count do
      post :load_cart, :id => @quote.id
    end
    assert_equal @quote.line_items.collect(&:product_id).sort, @cart.line_items.reload.collect(&:product_id).sort
  end
  
  test "replace_cart_items_with_quote_items" do
    setup_cart_and_quote
    assert_no_difference LineItem, :count do
      post :load_cart, :id => @quote.id, :replace => '1'
    end
    assert [[2, 2]] | collect_items(@cart, true)
  end
  
  test "merge_cart_items_with_quote_items" do
    setup_cart_and_quote
    assert_difference LineItem, :count do
      post :load_cart, :id => @quote.id, :replace => '0'
    end
    assert [[2, 2], [1, 1]] | collect_items(@cart, true).sort_by {|e| e[0] }
  end
  
  protected
  
    def setup_cart_and_quote
      @cart = create_cart(user = login_as(:admin))
      assert_equal [[1, 1]], collect_items(@cart)
      @quote = Quote.create(valid_quote(:user => user))
      @quote.add_item(ProductFormat.find(2), 2)
      assert_equal [[2, 2]], collect_items(@quote)
    end
    
end

require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :users, :sales_teams, :addresses

  test "should_create_user" do
    assert_difference User, :count do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  test "should_require_password" do
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors[:password]
    end
  end

  test "should_require_email" do
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors[:email]
    end
  end

  test "should_reset_password" do
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin@example.com', 'new password')
  end

  test "should_not_rehash_password" do
    users(:quentin).update_attributes(:email => 'quentin2@example.com')
    assert_equal users(:quentin), User.authenticate('quentin2@example.com', 'test')
  end

  test "should_authenticate_user" do
    assert_equal users(:quentin), User.authenticate('quentin@example.com', 'test')
  end

  test "should_set_remember_token" do
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end

  test "should_unset_remember_token" do
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end
  
  test "should_assign_new_user_as_head_sales_rep_for_new_team" do
    @team = SalesTeam.create(:name => 'New team')
    @user = create_user(:sales_team => @team)
    assert_equal @user.id, @team.reload.head_sales_rep.id
  end
  
  test "should_not_assign_new_user_as_head_sales_rep_for_existing_team" do
    @team = sales_teams(:dan)
    assert_not_nil @team.head_sales_rep
    @user = create_user(:sales_team => @team)
    assert_not_equal @user.id, @team.reload.head_sales_rep.id
  end

  test "should_return_name_for_string_conversion" do
    @user = users(:quentin)
    assert_equal @user.name, @user.to_s
  end

  test "should_check_admin_method" do
    @user = users(:quentin)
    assert_equal false, @user.admin?
    @user = users(:admin)
    assert_equal true, @user.admin?
  end

  test "should_check_customer_method" do
    @user = users(:quentin)
    assert_equal false, @user.customer?
    @user = users(:dallas_schools)
    assert_equal true, @user.customer?
  end

  test "should_check_primary_address" do
    @user = users(:another_customer)
    assert_equal addresses(:another_primary), @user.primary_address
  end

  protected
    def create_user(options = {})
      SalesRep.create({ :email => 'quire@example.com',
        :password => 'quire', :password_confirmation => 'quire',
        :name => 'Quire', :sales_team => sales_teams(:dan) }.merge(options))
    end
end

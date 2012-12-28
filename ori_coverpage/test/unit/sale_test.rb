require File.dirname(__FILE__) + '/../test_helper'

class SaleTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :line_item_collections, :products, :users, :card_authorizations
  
  def setup
    @sale = Sale.first
    @product = Title.first
    #@download = @product.create_download(:content_type => 'none', :filename => 'bob')
  end
  
  test "should_create_a_status_change_record_when_changed" do
    assert_difference StatusChange, :count, 1 do
      @sale.update_attribute(:status, 'Shipped')
    end
  end
  
  test "should_attempt_a_capture_when_changed_to_paid" do
    @sale.expects(:mark_as_paid).once.returns(true)
    @sale.update_attribute(:status, 'Paid')
  end
  
  test "should_attempt_a_cc_capture_if_card_authorization_exists" do
    @sale.card_authorization.expects(:capture).once.returns(true)
    @sale.mark_as_paid
  end
  
  test "should_void_authorization_when_cancelled" do
    @sale.expects(:mark_as_cancelled).once.returns(true)
    @sale.update_attribute(:status, 'Cancelled')
  end
  
  test "should_void_authorization_if_card_authorization_exists" do
    @sale.card_authorization.expects(:void_auth).once.returns(true)
    @sale.mark_as_paid
  end
  
#  test "should_add_a_download_from_a_sold_product_to_the_user" do
#    @sale.user.downloads.should.not.include(@download)
#    @sale.add_product(@product)
#    @sale.mark_as_paid
#    @sale.user.downloads.should.include(@download)
#  end
#
#  test "should_add_downloads_to_the_user_from_titles_belonging_to_a_set" do
#    @sale.add_product(@product.set)
#    @sale.mark_as_paid
#    @sale.user.downloads.should.include(@download)
#  end

end

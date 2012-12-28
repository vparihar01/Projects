require File.dirname(__FILE__) + '/../test_helper'

class QuoteTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :line_item_collections, :line_items, :users, :products
  
  def setup
    @quote = Quote.first
    @item = @quote.line_items.first
  end
  
  test "sales_team_is_assigned_via_user_when_creating_quote" do
    user = users(:quentin)
    assert_difference Quote, :count do
      user.quotes.create(:name => 'Foo')
    end
    assert_equal user.sales_team, Quote.find(:last).sales_team
  end
  
  test "copy_quote_to_quote" do
    @quote = Quote.first
    assert_difference Quote, :count do
      @new_quote = @quote.copy_to_quote
    end
    assert_equal "Copy of #{@quote.name}", @new_quote.name
    assert_equal @quote.line_items.collect(&:product_id), @new_quote.line_items.collect(&:product_id)
  end
end
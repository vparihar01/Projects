require File.dirname(__FILE__) + '/../test_helper'

class LineItemTest < ActiveSupport::TestCase
  fixtures :line_item_collections, :products, :product_formats, :line_items,
    :discounts, :bundles_products
  
  def setup
    # initialization for tests
  end

  # TODO Replace this with your real tests.
  test "truth" do
    assert true
  end
end

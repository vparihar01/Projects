require File.dirname(__FILE__) + '/../test_helper'

class CollectionTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :collections, :products, :users

  test "coversion_to_string" do
    @collection = collections(:one)
    assert_equal "#{@collection.id}-#{@collection.name.gsub(/[^a-z1-9]+/i, '-').downcase}", @collection.to_param
  end

  test "new_method" do
    @collection = collections(:one)
    assert !@collection.new?
    @collection = collections(:two)
    assert @collection.new?
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class ProductTest < ActiveSupport::TestCase
  fixtures :products

  test "name_less_article" do
    @product = Product.find(1)
    @old_name = @product.name
    ['A', 'An', 'The'].each do |article|
      @product.name = "#{article} #{@old_name}"
      assert_equal(@old_name, @product.name_less_article)
      assert_not_equal(@old_name, @product.name)
    end
  end
end

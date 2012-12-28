require File.dirname(__FILE__) + '/../test_helper'

class CategoryTest < ActiveSupport::TestCase
  fixtures :categories

  test "should_check_to_param_method" do
    Category.all.each do |category|
      assert "#{category.id}-#{category.name.gsub(/[^a-z1-9]+/i, '-').downcase}", category.to_param
    end
  end

  test "category_name_should_be_unique" do
    assert_difference 'Category.count', 0 do
      cat = Category.new( :name => Category.first.name )
      assert_raise ActiveRecord::RecordInvalid do
        cat.save!
      end
      assert_equal cat.errors['name'], ["has already been taken"]
    end
  end
end

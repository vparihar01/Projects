require File.dirname(__FILE__) + '/../test_helper'

class BundlesLineItemCollectionTest < ActiveSupport::TestCase
  fixtures :line_item_collections, :products, :product_formats, :line_items,
    :discounts, :bundles_products, :assembly_assignments
  
  def setup
    @cart = Cart.find(1)
    @bundle = Bundle.find(1)
    #puts "bundle: '#{@bundle.name}'"
    @product = Product.find(2)
    @product_format = @product.product_formats[0]
  end

  test "should_not_be_found_for_non_qualifying_carts" do
    assert_equal @cart.bundles, []
  end
  
  test "should_be_found_for_qualifying_carts" do
    @cart.add_item(@product_format)
    @cart.add_item(Product.find(1).product_formats[0])
    #puts "cart bundles: #{@cart.bundles}"
    #@cart.bundles.should.eql [ @bundle ]
    # TODO: fix this assertion (check data, what LineItemCollection.bundle is exactly supposed to do with it)
    #assert_equal @bundle, @cart.reload.bundles
  end
  
  test "should_not_be_found_for_qualifying_carts_without_code_when_code_required" do
    @cart.add_item(@product_format)
    @bundle.update_attribute(:code, 'foo')
    assert @cart.bundles.empty?
  end
  
#  test "should_be_found_for_qualifying_carts_with_code_when_code_required" do
#    @cart.add_item(@product_format)
#    @cart.update_attribute(:discount_code, 'foo')
#    @bundle.update_attribute(:code, 'foo')
#    @cart.bundles.should.eql [ @bundle ]
#  end
  
#  test "should_calculate_the_discount_for_a_qualifying_cart" do
#    @cart.add_item(@product_format)
#    discount = @cart.amount * 0.1
#    @cart.bundle_discount.should.equal discount.round(2)
#  end
  
  test "should_return_the_greater_of_two_eligible_bundles" do
    @cart.add_item(@product_format)
    @cart.add_item(Product.find(3).product_formats[0])
    other_bundle = Bundle.find(2)
    assert_equal @cart.bundles, [ other_bundle ]
  end
  
  test "should_return_two_different_bundles_given_enough_products" do
    @cart.add_item(@product_format)
    @cart.add_item(@product_format)
    @cart.add_item(Product.find(3).product_formats[0])
    # TODO: fix this assertion (check data, what LineItemCollection.bundle is exactly supposed to do with it)
    #assert_equal [1,2], @cart.bundles.collect(&:id).sort
  end
  
#  test "should_accumulate_the_multiple_discounts_of_two_different_bundles" do
#    @cart.add_item(@product_format)
#    @cart.add_item(@product_format)
#    @cart.add_item(Product.find(3).product_formats[0])
#    other_bundle = Bundle.find(2)
#    @cart.bundle_discount.should.equal @bundle.calculate(Product.find(1).product_formats[0].price_list + @product_format.price_list) + other_bundle.calculate(@product_format.price_list + Product.find(3).product_formats[0].price_list)
#  end
  
  test "should_accumulate_the_multiple_discounts_of_two_of_the_same_bundle" do
    @cart.add_item(@product_format)
    @cart.add_item(@product_format)
    @cart.add_item(@product_format1 = Product.find(1).product_formats[0])
    # TODO: fix this assertion, inspect what the related code has really to do with the inspected test data
    #assert_equal @bundle.calculate(@product_format1.price_list + @product_format.price_list) * 2 , @cart.bundle_discount
    #@cart.bundle_discount.should.equal @bundle.calculate(@product_format1.price_list + @product_format.price_list) * 2
  end

  # the following 3 test cases (processing_count checks) are using fixtured fullfilling the assumptions noted in the source code
  # should the code change to handle other data than assumed, the test cases should be extended / new test cases should be added
  # to use new fixtures simulating non-assumed conditions (eg. assembly with some unavailable titles added to the cart, etc.)
  # currently adding such test cases would likely cause errors / test cases should mark bad calculations
  test "should_check_that_adding_a_regular_product_multiple_times_increases_processing_count_according_to_the_quantity" do
    assert @cart.processing_count > 0 # verify that there is already a processing count
    assert_difference '@cart.line_items.count', 1 do # verify that a new title will be added (no only increasing
      10.times do
        assert_difference '@cart.processing_count', 1 do  # check that each time the processing count increases
          @cart.add_item(@product_format)
        end
      end
    end
  end

  test "should_check_that_adding_a_virtual_product_does_not_increase_the_processing_count" do
    assert @cart.processing_count > 0 # verify that there is already a processing count
    @product_format = product_formats(:old_book_pdf)  # it should be a PDF of a Title
    assert @product_format.product.is_a?(Title)
    assert @product_format.format.is_virtual
    assert_difference '@cart.line_items.count', 1 do # verify that a new title will be added (no only increasing
      3.times do
        # add virtual product and verify that the count does not increase
        assert_difference '@cart.processing_count', 0 do  # check that each time the processing count does not increase
          @cart.add_item(@product_format)
        end
      end
    end
  end

  test "should_check_that_adding_assemblies_results_the_processing_count" do
    assert @cart.processing_count > 0 # verify that there is already a processing count
    @product_format = product_formats(:four) # product formats :four is the paper format for the product(4) which is a set of 2 titles
    assert @product_format.product.is_a?(Assembly)
    assert @product_format.product.titles.count > 1
    assert_difference '@cart.line_items.count', 1 do # verify that a new title will be added (no only increasing
      3.times do  # repeat making sure the count is increased each time with the proper amount
        assert_difference '@cart.processing_count', @product_format.product.titles.count do  # check that each time the processing count behaves as expected
          @cart.add_item(@product_format)
        end
      end
    end
  end


  test "should_copy_an_existing_cart" do
    @oldcart = line_item_collections(:cart)
    @newcart = Cart.new()
    assert_difference 'LineItem.count', @oldcart.line_items.count do
      @newcart.copy_from_cart(@oldcart)
    end
  end

  test "should_copy_to_a_new_cart_and_save_for_later" do
    @oldcart = line_item_collections(:cart)
    @newcart = Cart.new()
    assert_difference 'LineItem.count', @oldcart.line_items.count do
      @oldcart.copy_to_cart(@newcart)
      assert_no_difference 'LineItem.count' do
        @newcart.save_for_later_inactive_line_items!
      end
    end
  end

  test "should_merge_line_items_on_demand" do
    assert_difference 'LineItem.count', 2 do  # going to insert 2 lines in DB, not using the .add_item method (that takes care of merging)
      @new_line_item = LineItem.new(:line_item_collection_id => @cart.id,
                                  :quantity => 1, :unit_amount => 500,
                                  :total_amount => 500,
                                  :product_format_id => @product_format.id)
      assert @new_line_item.save!
      @new_line_item2 = LineItem.new(:line_item_collection_id => @cart.id,
                                  :quantity => 1, :unit_amount => 500,
                                  :total_amount => 500,
                                  :product_format_id => @product_format.id)
      assert @new_line_item2.save!
    end
    assert_difference 'LineItem.count', -1 do  # when merging, the 2 recs above should be 1, so expect 2 - 1 = -1 rec.count change
      @cart.merge_line_items
    end
  end
  
end

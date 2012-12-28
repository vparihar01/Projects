require File.dirname(__FILE__) + '/../test_helper'

class ProductFormatTest < ActiveSupport::TestCase
  fixtures :product_formats, :products, :formats

  def setup
    @valid_isbn   = "9781610800570"
    @valid_isbn10 = "1610800575"
    @invalid_isbn = "1234567890123"
  end

  test "should_not_create_without_required_fields" do
    @product_format = ProductFormat.new()
    assert !@product_format.save
    assert @product_format.errors.collect { |field,error| "#{field} #{error}" }.include?("product_id can't be blank")
    assert @product_format.errors.collect { |field,error| "#{field} #{error}" }.include?("format_id can't be blank")
    assert @product_format.errors.collect { |field,error| "#{field} #{error}" }.include?("isbn can't be blank")
  end

  test "should_not_create_with_reference_to_invalid_product" do
    @product = nil
    @product_format = ProductFormat.new( :product_id => Product.all.last.id + 1, :format_id => 1 )
    assert !@product_format.save
    assert @product_format.errors.collect { |field,error| "#{field} #{error}" }.include?("base Invalid Product ID provided")
  end

  test "should_not_create_with_invalid_isbn" do
    @product_format = ProductFormat.new(:product_id => Product.all.last.id, :format_id => 1, :isbn => @invalid_isbn)
    assert !@product_format.save
    assert @product_format.errors.values.flatten.include?("is not a valid ISBN code")
  end

  test "should_create_valid_product_format" do
    CONFIG[:calculate_list_price] = true      # override config (if specifies false) to increase CC
    @product = products(:no_format_record)
    @format = formats(:hardcover)
    assert_difference 'ProductFormat.count' do
      @product_format = ProductFormat.new( :product_id => @product.id, :format_id => @format.id, :isbn => @valid_isbn )
      assert @product_format.save
      assert_equal @format.name, @product_format.to_s
      assert_equal @valid_isbn, @product_format.isbn13.to_s
      assert_equal @valid_isbn10, @product_format.isbn10.to_s
      assert_equal (@product && @product.available? && @product_format.status == ProductFormat::ACTIVE_STATUS_CODE), @product_format.active?
      # TODO add more assertions based on the current code (inspect fields)
    end
  end

  test "should_create_valid_pdf_product_format" do
    CONFIG[:calculate_list_price] = true      # override config (if specifies false) to increase CC
    @product = products(:no_format_record)
    @format = formats(:pdf)
    assert_difference 'ProductFormat.count' do
      @product_format = ProductFormat.new( :product_id => @product.id, :format_id => @format.id, :isbn => @valid_isbn )
      assert @product_format.save
      assert_equal @format.name, @product_format.to_s
      assert_equal @valid_isbn, @product_format.isbn13.to_s
      assert_equal @valid_isbn10, @product_format.isbn10.to_s
      assert_equal (@product && @product.available? && @product_format.status == ProductFormat::ACTIVE_STATUS_CODE), @product_format.active?
      # TODO add more assertions based on the current code (inspect fields)
    end
  end

  test "should_create_valid_set_product_format" do
    CONFIG[:calculate_list_price] = true      # override config (if specifies false) to increase CC
    @product = products(:set)
    @format = formats(:pdf)
    assert_difference 'ProductFormat.count' do
      @product_format = ProductFormat.new( :product_id => @product.id, :format_id => @format.id, :isbn => @valid_isbn )
      assert @product_format.save
      assert_equal @format.name, @product_format.to_s
      assert_equal @valid_isbn, @product_format.isbn13.to_s
      assert_equal @valid_isbn10, @product_format.isbn10.to_s
      assert_equal (@product && @product.available? && @product_format.status == ProductFormat::ACTIVE_STATUS_CODE), @product_format.active?
      # TODO refine this test case (perhaps also the fixtures) to cover collection price summing code branch
    end
  end

  # TODO add more assertions to check actual field values, value changes

  # TODO Implement more tests
end

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/isbn.rb'
include ISBNtools

class ISBNtoolsTest < ActiveSupport::TestCase
  def setup
    @isbn_10_raw = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 ]
    @isbn_13_raw = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3 ]
    #@isbn_a = '1234567890123'
  end

  test "10_digit_conversion" do
    @cd_10 = cd10(@isbn_10_raw)
    assert_not_nil @cd_10
    assert_equal 10, @cd_10
    @put_cd10 = put_cd10(@isbn_10_raw)
    assert_equal [1,2,3,4,5,6,7,8,9,@cd_10], @put_cd10
  end

  test "13_digit_conversion" do
    @cd_13 = cd13(@isbn_13_raw)
    assert_not_nil @cd_13
    assert_equal 8, @cd_13
    @put_cd13 = put_cd13(@isbn_13_raw)
    assert_equal [1,2,3,4,5,6,7,8,9,0,1,2,@cd_13], @put_cd13
  end

  test "put_cd" do
    [ [@isbn_10_raw,put_cd10(@isbn_10_raw)], [@isbn_13_raw,put_cd13(@isbn_13_raw)] ].each do |isbn,cd|
      @put_cd = put_cd(isbn)
      assert_equal cd, @put_cd
    end
  end

  test "isbnchar_conversion" do
    @chars = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, "a", "b", "c" ]
    @isbnchars = @chars[0..9].collect {|c| c.to_s }.push( 'X', '0', '*', "a", "b", "c" )
    @chars.zip(@isbnchars).each do |char,isbnchar|
      @isbnchar = isbnchar(char)
      assert_equal isbnchar, @isbnchar
    end
  end

  test "isbn_creation_from_integer" do
    @isbn = 1234567890.to_isbn
    assert_equal "123456789X", @isbn.to_s
  end

  test "isbn_creation_from_array" do
    assert_equal "123456789X", @isbn_10_raw.to_isbn.to_s
  end

end

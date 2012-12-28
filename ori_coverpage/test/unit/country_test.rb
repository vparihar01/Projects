require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < ActiveSupport::TestCase
  def setup
    # any initialization needed for the tests
  end

  test "should_check_country_string_conversion" do
    Country.all.each do |country|
      assert_equal country.name, country.to_s
    end
  end
end

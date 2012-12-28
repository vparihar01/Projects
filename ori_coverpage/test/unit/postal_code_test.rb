require File.dirname(__FILE__) + '/../test_helper'

class PostalCodeTest < ActiveSupport::TestCase
  fixtures :postal_codes, :zones

  def setup
    # any initialization needed for the tests
  end

  test "should_check_validations" do
    # TODO: write test case
    @postal_code = PostalCode.new()
    @zone = Zone.all.first
    #validates_presence_of :name, :zone_id
    assert !@postal_code.save       # missing: zone_id, name
    @postal_code.zone_id = @zone.id
    assert !@postal_code.save       # missing: name
    @postal_code.name = PostalCode.all.first.name # pick an existing name
    assert !@postal_code.save       # name must be unique
    @postal_code.name << "_test"    # update name
    assert @postal_code.save
  end

  test "should_check_postal_code_string_conversion" do
    PostalCode.all.each do |postal_code|
      assert_equal "#{postal_code.zone.code}  #{postal_code.name}", postal_code.to_s
    end
  end
end

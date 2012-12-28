require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/time_calculations.rb'
#no module to be included as lib/time_calculations.rb extends ActiveSupport::CoreExtensions::Time::Calculations (core extension)

class TimeCalculationsTest < ActiveSupport::TestCase
  def setup
    @time = Time.now
  end

  test "end_of_day" do
    @eod = Time.new.end_of_day
    assert_equal @time.change(:hour => 23, :min => 59, :sec => 59, :usec => 999999.999), @eod
  end

end

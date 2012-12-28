require File.dirname(__FILE__) + '/../test_helper'
include UPS

class UpsTest < ActiveSupport::TestCase
  def setup
    @ups_client = UPS::Client.new( YAML.load_file(Rails.root.join('config', 'ups.yml')) )
  end

  # TODO: Replace this with your real tests.
  test "should_test_a_couple_of_rates" do
    weight = 0      # weight will be increased over tests
    rates = []      # store rates retrieved in here
    3.times do        # number of tests
      weight += 1     # weight is increased by 1 each time (this way it also will serve as an index in rates[])
      rates << @ups_client.rate('36608', weight)    # get rate
      assert_not_nil rates[weight-1]                  # should not be nil
    end
    assert_equal rates, rates.sort                    # higher the weight, higher the rate should be
  end
end

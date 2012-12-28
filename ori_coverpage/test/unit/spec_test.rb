require File.dirname(__FILE__) + '/../test_helper'

class SpecTest < ActiveSupport::TestCase
  fixtures :specs

  test "should_list_inclusion_labels" do
    @spec = Spec.new(:include_tests => true)
    assert_equal ['Accelerated Reader Tests'], @spec.inclusions
    @spec.include_labels = true
    assert @spec.inclusions.include?('Barcode Labels')
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class RecipientTest < ActiveSupport::TestCase

  test "should load recipients" do
    assert Recipient.all.any?
  end

  test "should output name in string context" do
    @recipient = Recipient.first
    assert_not_nil @recipient
    assert_equal @recipient.to_s, @recipient.name
  end

  test "should return email array" do
    @recipient = recipients(:data_test_onix)
    assert_not_nil @recipient
    assert_equal 2, @recipient.email_array.count
  end

end

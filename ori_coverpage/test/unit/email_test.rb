require File.dirname(__FILE__) + '/../test_helper'
# Email: acts_without_database :email => :string, :message => :string, :cc => :integer
class EmailTest < ActiveSupport::TestCase
  def setup
    # any initialization needed for the tests
  end

  # TODO Replace this with your real tests.
  test "truth" do
    assert true
  end

  test "should_fail_on_invalid_addresses_and_accept_valid_address" do
    @email = Email.new()
    assert !@email.valid?    # should not accept empty email
    @email.email = 'abc'
    assert !@email.valid?    # not an email
    @email.email = '@abc.com'
    assert !@email.valid?    # not an email
    @email.email = 'abc@abc.com'
    assert @email.valid?     # looks like a valid email
  end
end

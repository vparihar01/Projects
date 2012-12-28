require File.dirname(__FILE__) + '/../test_helper'

class ContactTest < ActiveSupport::TestCase
  # Contact: acts_without_database :name => :string, :email => :string, :comments => :string, :subscribe => :integer
  
  test "should_not_create_new_contact_request_without_required_fields" do
    @contact = Contact.new()
    assert !@contact.valid?       # missing: email, name, comments
    @contact.email = 'john.doe@gmail.com'
    assert !@contact.valid?       # missing: name, comments
    @contact.name = 'John Doe'
    assert !@contact.valid?       # missing: comments
    @contact.comments = 'Got so much to say...'
    assert @contact.valid?        # should be ok now
  end
end

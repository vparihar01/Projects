require File.dirname(__FILE__) + '/../test_helper'

class DataRecipientTest < ActiveSupport::TestCase

  def setup
    @recipient = recipients :data_test
  end

  test "should_get_first_recipient" do
    recipient = DataRecipient.first
    assert recipient.valid?
  end

  test "should_distribute" do
    options = {
      :debug => false,
      :verbose => false,
    }
    products = Title

    DataRecipient.all.each do |recipient|
      result = recipient.distribute(products, options)
      assert result
      unless options[:debug]
        notification_email = ActionMailer::Base.deliveries.last
        assert_equal notification_email.subject, "#{CONFIG[:app_name]}: Product data"
        if recipient.ftp.blank?
          assert_equal notification_email.attachments.count, 1
          assert_match /Please find attached/, notification_email.encoded
        else
          assert_equal notification_email.attachments.count, 0
          assert_match /has been uploaded/, notification_email.encoded
        end
      end
    end
  end

  test "should_distribute_select" do
    options = {
      :debug => false,
      :verbose => false,
    }
    isbns = 'old, recent'
    products = Product.find_using_options(:product_select => "by_isbn", :isbns => isbns)

    DataRecipient.all.each do |recipient|
      result = recipient.distribute(products, options)
      assert result
      unless options[:debug]
        notification_email = ActionMailer::Base.deliveries.last
        assert_equal notification_email.subject, "#{CONFIG[:app_name]}: Product data"
      end
    end
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class ImageRecipientTest < ActiveSupport::TestCase

  def setup
    CONFIG[:image_archive_dir] = Rails.root.join("test/fixtures/files")
    @recipient = recipients :images_test
  end

  test "should_get_first_recipient" do
    recipient = ImageRecipient.first
    assert recipient.valid?
  end

  test "should_distribute" do
    options = {
      :debug => false,
      :verbose => false,
      :force => true,
      :clean => true,
    }
    products = Title.find_using_options

    ImageRecipient.all.each do |recipient|
      result = recipient.distribute(products, options)
      error = result.values.include?(false)
      assert !error
      unless error || options[:debug]
        notification_email = ActionMailer::Base.deliveries.last
        assert_equal notification_email.subject, "#{CONFIG[:app_name]}: Images delivered"
      end
    end
  end

  test "should_distribute_select" do
    options = {
      :debug => false,
      :verbose => false,
      :force => true,
      :clean => true,
      :image_types => 'covers',
      :image_formats => 'jpg',
    }
    isbns = '9781609731939, 9781609737207'
    products = Title.find_using_options(:product_select => "by_isbn", :isbns => isbns)

    ImageRecipient.all.each do |recipient|
      result = recipient.distribute(products, options)
      error = result.values.include?(false)
      assert !error
      unless error || options[:debug]
        notification_email = ActionMailer::Base.deliveries.last
        assert_equal notification_email.subject, "#{CONFIG[:app_name]}: Images delivered"
      end
    end
  end
end

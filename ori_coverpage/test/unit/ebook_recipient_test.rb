require File.dirname(__FILE__) + '/../test_helper'

class EbookRecipientTest < ActiveSupport::TestCase

  def setup
    @recipient = recipients :ebooks_test
    # copy fixture files to test ebooks directory (see ProductDownload attachments definition)
    ProductDownload.all.each do |pd|
      ff_path = Rails.root.join('test/fixtures/files', File.basename(pd.public_filename))
      FileUtils.mkdir_p(File.dirname(pd.public_filename))
      FileUtils.cp(ff_path, pd.public_filename)
    end
  end

  test "should_get_first_recipient" do
    recipient = EbookRecipient.first
    assert recipient.valid?
  end

  test "should_distribute" do
    options = {
      :debug => false,
      :verbose => false,
    }
    products = Title.find_using_options

    EbookRecipient.all.each do |recipient|
      result = recipient.distribute(products, options)
      assert result
      unless options[:debug]
        notification_email = ActionMailer::Base.deliveries.last
        assert_equal notification_email.subject, "#{CONFIG[:app_name]}: Ebooks delivered"
        assert_match /text\/csv/, notification_email.attachments[0]['Content-Type'].to_s if recipient.preferred_ebook_include_manifest
      end
    end
  end

  test "should_distribute_select" do
    options = {
      :debug => false,
      :verbose => false,
    }
    isbns = '9781609731939, 9781609737207'
    products = Title.find_using_options(:product_select => "by_isbn", :isbns => isbns)

    EbookRecipient.all.each do |recipient|
      result = recipient.distribute(products, options)
      assert result
      unless options[:debug]
        notification_email = ActionMailer::Base.deliveries.last
        assert_equal notification_email.subject, "#{CONFIG[:app_name]}: Ebooks delivered"
      end
    end
  end
end

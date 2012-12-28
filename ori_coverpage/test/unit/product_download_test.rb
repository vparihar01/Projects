require File.dirname(__FILE__) + '/../test_helper'

class ProductDownloadTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :sales_teams, :addresses, :product_downloads, :products, :formats, :product_formats

  def setup
    # test initializations go here...
    #@product_download = product_downloads(1)
    #@title = Title.first
    #@product = Product.first
  end

  test "trigger product download excerpt creation" do
    # prepare...
    # copy the test pdf to ebooks
    # TODO: make these paths and stuff dynamic by reading ProductDownload table records and use public_filename
    target_dir = "#{Rails.root.to_s + "/tmp/protected/ebooks/0000/0002"}"  # 0002 comes from fixtures/product_downloads.yml
    FileUtils.mkdir_p target_dir  unless File.exist?(target_dir)
    FileUtils.copy_file( Rails.root.to_s + "/test/fixtures/files/anothertest.pdf", Rails.root.to_s + "/tmp/protected/ebooks/0000/0002/anothertest.pdf" )
    @product_download = product_downloads(:anotherone)

    assert @product_download.save # should trigger excerpt creation
    # we never make it here due to issue #312 - check and fix that

    # cleanup test files
    FileUtils.rm( target_dir + "/anothertest.pdf" )

  end

  # TODO Replace this with your real tests.
  test "truth" do
    assert true
  end
end

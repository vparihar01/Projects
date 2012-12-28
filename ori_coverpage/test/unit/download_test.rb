require File.dirname(__FILE__) + '/../test_helper'

class DownloadTest < ActiveSupport::TestCase
  fixtures :downloads

  test "should_not_create_downloads_without_required_fields" do
    @download = Download.new()  # missing all fields
    assert !@download.save
    @download.title = "test"                # title is required
    assert !@download.save
    @download.description = "test download" # description is required
    assert !@download.save
    @download.filename = "testfile.txt"     # filename is required
    assert !@download.save
    @download.size = 1                      # size is required
    assert @download.save     # now should save
  end

  test "should_increase_view_counter" do
    Download.all.each do |download|
      viewed = download.views
      download.mark_as_viewed
      assert_equal download.views, viewed + 1
    end
  end

  test "should_detect_nonexisting_file_with_nil_mtime" do
    @download = downloads(:one)
    assert !@download.exist?
    assert_nil @download.mtime
  end

  test "should_recognize_some_filetypes" do
    assert_equal downloads(:one).file_type, "Text"
  end

  #TODO: should add test cases with actual existing files, so "rename" and "mtime" methods can be covered
end

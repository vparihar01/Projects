require File.dirname(__FILE__) + '/../test_helper'

class ExcerptTest < ActiveSupport::TestCase
  fixtures :excerpts, :products
  
  def setup
    # any initialization needed for the tests...
  end

  test "should_tell_when_a_file_does_not_exist_mtime_should_be_nil_as_well" do
    @excerpt = excerpts(:one)
    assert !@excerpt.exist?
    assert_nil @excerpt.mtime
    assert_nil @excerpt.update_ipaper_settings
  end

  test "should_test_operations_on_local_files" do
    @excerpt = excerpts(:one)
    # copy the test pdf to ebooks
    FileUtils.mkdir_p( Rails.root.to_s + "/tmp/protected/excerpts/0000/0001" )
    FileUtils.copy_file( Rails.root.to_s + "/test/fixtures/files/anothertest.pdf", @excerpt.full_filename )

    assert @excerpt.mtime

    # cleanup test files
    FileUtils.rm( @excerpt.full_filename  )
  end

  test "should_test_ipaper_update" do
    @excerpt = excerpts(:one)
    # copy the test pdf to ebooks
    FileUtils.mkdir_p( Rails.root.to_s + "/tmp/protected/excerpts/0000/0001" )
    FileUtils.copy_file( Rails.root.to_s + "/test/fixtures/files/anothertest.pdf", @excerpt.full_filename )

    assert @excerpt.save
    assert @excerpt.ipaper_id
    assert @excerpt.ipaper_access_key

    # cleanup test files
    FileUtils.rm( @excerpt.full_filename  )
  end

  #TODO: add fixtures / test cases that deal with existing files
end

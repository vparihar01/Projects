require File.dirname(__FILE__) + '/../test_helper'

class LinkTest < ActiveSupport::TestCase
  fixtures :links

  test "should_not_create_without_url" do
    @link = Link.new(:title => 'Without URL')
    assert !@link.save
  end

  test "should_not_create_with_invalid_url" do
    @link = Link.new(:title => 'Invalid URL', :url => 'http://youdontgoanywheremyfriend')
    assert !@link.save
    @link = Link.new(:title => 'Invalid URL', :url => 'microsoft.com')
    assert !@link.save
  end
  
  test "should_not_create_with_no_response_url" do
    @link = Link.new(:title => 'No Response URL', :url => 'http://youdontgoanywheremyfriend.com')
    assert !@link.save
  end

  # check that title is returned in this order (title, meta_title, url)
  # in case any of the fields is not filled /url is mandatory/
  test "test_titles" do
    @link = links(:one) # this one has all concerned fields
    assert @link.link_title == @link.title
    @link = links(:without_title) # this one is missing title
    assert @link.link_title == @link.meta_title
    @link = links(:without_any_title) # this one has no title whatsoever
    assert @link.link_title == @link.url
  end

  test "should_get_adults_only_links" do
    @links = Link.adult_items
    assert !@links.empty? # fixtures should define some adult links
    @links.each do |link|
      assert link.is_adults
    end
  end

  test "should_get_kids_only_links" do
    @links = Link.kid_items
    assert !@links.empty? # fixtures should define some kids links
    @links.each do |link|
      assert link.is_kids
    end
  end

  test "should_increase_view_count" do
    @link = links(:two)
    10.times do
      assert_difference 'links(:two).views' do
        @link.mark_as_viewed
      end
    end
  end

  test "should_check_is_ok_functionality" do
    Link.all.each do |link|
      assert_equal( (link.code == 200), link.is_ok? )
    end
  end

  test "should_check_ok" do
    Link.ok.each do |link|
      assert_equal 200, link.code
      assert_nil link.deleted_at
    end
  end

  test "should_check_paginate_ok" do
    @links = Link.ok.paginate(:page => '1', :per_page => '1')
    assert_equal 1, @links.size
    @links.each do |link|
      assert_equal 200, link.code
      assert_nil link.deleted_at
    end
  end

  test "mark_as_modified" do
    @start_time = Time.now
    sleep(5)
    Link.ok.each do |link|
      link.mark_as_modified
      assert @start_time < link.reload.updated_at
    end
  end

  test "to_dropdown" do
    @links_dropdown = Link.to_dropdown
    assert_equal Link.all.count, @links_dropdown.count
    @links_dropdown.each do |title,id|
      link = Link.find(id)
      assert_equal title, link.link_title
    end
  end

  test "get_responses" do
    # test a valid link
    @response = links(:one).get_response
    assert @response.is_a?(Net::HTTPFound)

    # test a link with another proto than  HTTP
    @link = links(:wrongproto)
    @response = @link.get_response
    assert @link.errors.full_messages.include?( "Url " + Link::ERROR_MESSAGES[:wrong_protocol] ) # "must be the URL for a website"

    # test a link with an invalid url
    @link = links(:malformed)
    @response = @link.get_response
    assert @link.errors.full_messages.include?( "Url " + Link::ERROR_MESSAGES[:malformed_url] ) # "must be the URL for a website"

    # test a link with a not existing url
    @link = links(:notfound)
    @response = @link.get_response
    assert @link.errors.full_messages.include?( "Url " + Link::ERROR_MESSAGES[:no_response] ) # "must be the URL for a website"

    # TODO: meditate how it would be possible to trigger a timeout to reach 100% CC on Link
  end

end

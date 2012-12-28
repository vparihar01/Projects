require File.dirname(__FILE__) + '/../test_helper'

class HeadlineTest < ActiveSupport::TestCase
  fixtures :headlines

  test "create_headline" do
    assert_difference 'Headline.count' do
      @headline = Headline.new(:title => 'Headline 3', :body => 'Some text for headline three...')
      assert @headline.save
    end
  end

  test "should_return_the_last_headline" do
    assert_equal Headline.last, Headline.find_latest(1).first
  end
end

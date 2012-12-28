require File.dirname(__FILE__) + '/../test_helper'

class ContributorTest < ActiveSupport::TestCase
  fixtures :contributors

  test "should_return_name_less_article" do
    Contributor.all.each do |contributor|
      assert_equal contributor.name.gsub(/^(Dr\.|Mr\.|Miss|Mrs\.|Professor) /i, ''), contributor.name_less_article
    end
  end

  test "should_generate_dropdown_list_with_all_items" do
    @contrib_drop_list = Contributor.to_dropdown
    i = 0
    Contributor.all.sort_by(&:name_less_article).each do |contributor|
      assert @contrib_drop_list[i][0] = contributor.name
      i += 1
    end
  end
end

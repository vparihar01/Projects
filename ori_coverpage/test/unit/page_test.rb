require File.dirname(__FILE__) + '/../test_helper'

class PageTest < ActiveSupport::TestCase

  test "title_should_be_present" do
    assert_difference 'Page.count', 1 do
      @page = Page.new(valid_page)
      @page.save!
    end

    @page.destroy

    assert_difference "Page.count", 0 do
      (invalid_page = valid_page)['title'] = ""
      @page = Page.new(invalid_page)
      assert_raise ActiveRecord::RecordInvalid do
        @page.save!
      end
      assert_equal @page.errors['title'], ["can't be blank"]
    end
  end

  test "path_should_be_unique" do
    assert_difference 'Page.count', 1 do
      @page = Page.new(valid_page)
      @page.save!
    end

    assert_difference "Page.count", 0 do
      @page = Page.new(valid_page)
      assert_raise ActiveRecord::RecordInvalid do
        @page.save!
      end
      assert_equal @page.errors['path'], ["has already been taken"]
    end
  end

  test "layout_should_be_defined_in_config" do
    assert_difference 'Page.count', 0 do
      @page = Page.new(valid_page.merge({'layout' => 'somethingdefinitelyundefined#_'}))
      assert_raise ActiveRecord::RecordInvalid do
        @page.save!
      end
      assert_equal @page.errors['layout'], ["is not included in the list"]
    end
  end

  test "layout_should_allow_blank" do
    assert_difference 'Page.count', 1 do
      @page = Page.new(valid_page.merge({'layout' => ''}))
      @page.save!
    end
  end

end

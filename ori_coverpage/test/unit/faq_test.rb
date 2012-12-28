require File.dirname(__FILE__) + '/../test_helper'

class FaqTest < ActiveSupport::TestCase
  fixtures :faqs, :tags, :taggings

  # TODO: Replace this with your real tests.
  test "truth" do
    assert true
  end

  test "should_not_add_faq_without_answer" do
    assert_no_difference 'Faq.count' do
      @faq = Faq.new( :question => "A QUESTION" )
      assert !@faq.save
    end
  end

  test "should_not_add_faq_without_question" do
    assert_no_difference 'Faq.count' do
      @faq = Faq.new( :answer => "AN ANSWER" )
      assert !@faq.save
    end
  end

  test "should_add_faq_with_question_and_answer" do
    assert_difference 'Faq.count' do
      @faq = Faq.new( :question => "A QUESTION", :answer => "AN ANSWER" )
      assert @faq.save
    end
  end

  test "should_delete_faq" do
    assert_difference "Faq.count", -1 do
      Faq.delete 3
    end
  end

end

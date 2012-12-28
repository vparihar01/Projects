require File.dirname(__FILE__) + '/../test_helper'

class TestimonialTest < ActiveSupport::TestCase
  fixtures :testimonials

  test "should_not_create_testimonial" do
    assert_difference 'Testimonial.count', 0 do
      @testimonial = Testimonial.new()
      assert !@testimonial.save
      assert @testimonial.errors.collect { |field,error| "#{field} #{error}" }.include?("comment can't be blank")
    end
  end

  test "should_create_valid_testimonial" do
    assert_difference 'Testimonial.count' do
      @testimonial = Testimonial.new( :comment => 'very nice' )
      assert @testimonial.save
    end
  end

  test "should_check_random_testimonials" do
    @testimonials = []
    10.times do
      @testimonials[@testimonials.size] = Testimonial.find_random(1)
      assert_not_nil @testimonials.last
    end
  end

  test "should_check_finding_latest" do
    @old_latest = Testimonial.find_latest(2)
    assert_not_nil @old_latest
    assert_equal 2, @old_latest.count # expecting 2+ records in fixture

    # add a new one, that should be the latest
    assert_difference 'Testimonial.count' do
      @testimonial = Testimonial.new( :comment => 'this is the latest testimonial' )
      assert @testimonial.save
    end

    @new_latest = Testimonial.find_latest(2)
    assert_not_nil @new_latest
    assert_equal 2, @new_latest.count

    # check that the new list of latest items is as expected
    assert_not_equal @old_latest, @new_latest
    assert_not_equal @old_latest.first, @new_latest.first
    assert_equal @old_latest.first, @new_latest.last # verify how items were 'shifted'
    assert_equal @testimonial, @new_latest.first     # first item in the new latest list must be the one we just added
  end

end

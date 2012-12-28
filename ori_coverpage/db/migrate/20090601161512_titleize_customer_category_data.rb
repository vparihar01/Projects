class TitleizeCustomerCategoryData < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
      new_category = user.category.blank? ? nil : user.category.titleize
      user.update_attribute(:category, (Customer::CATEGORIES.include?(new_category) ? new_category : nil))
    end
  end

  def self.down
    User.all.each do |user|
      new_category = user.category.blank? ? nil : user.category.downcase
      user.update_attribute(:category, new_category)
    end
  end
end

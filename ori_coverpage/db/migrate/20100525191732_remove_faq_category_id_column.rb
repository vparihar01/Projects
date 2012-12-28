class RemoveFaqCategoryIdColumn < ActiveRecord::Migration
  def self.up
    remove_column :faqs, :faq_category_id
  end

  def self.down
    add_column :faqs, :faq_category_id, :integer
  end
end

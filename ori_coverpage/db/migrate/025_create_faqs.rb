class CreateFaqs < ActiveRecord::Migration
  def self.up
    create_table :faqs do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "question", :string
      t.column "answer", :text
      t.column "faq_category_id", :integer
    end
    
    create_table :faq_categories do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "name", :string, :default => "", :null => false
      t.column "description", :text
    end

    add_index "faq_categories", ["name"], :name => "idx_name"
  end

  def self.down
    drop_table :faqs
    drop_table :faq_categories
  end
end

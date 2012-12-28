class CreateTeachingGuides < ActiveRecord::Migration
  def self.up
    create_table :teaching_guides do |t|
      t.string :name
      t.string :category
      t.text :rationale
      t.text :objective
      t.integer :interest_level_min_id
      t.integer :interest_level_max_id
      t.text :body
      t.string :document
      t.integer :download_counter
      t.timestamps
    end
    create_table :products_teaching_guides, :id => false do |t|
      t.integer :product_id
      t.integer :teaching_guide_id
    end
    add_index :products_teaching_guides, ["product_id"]
  end

  def self.down
    drop_table :teaching_guides
    drop_table :products_teaching_guides
  end
end

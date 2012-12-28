class RemoveCategoryFromTeachingGuide < ActiveRecord::Migration
  def self.up
    remove_column :teaching_guides, :category
  end

  def self.down
    add_column :teaching_guides, :category, :string
  end
end

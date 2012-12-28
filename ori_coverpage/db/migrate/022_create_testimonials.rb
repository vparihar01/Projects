class CreateTestimonials < ActiveRecord::Migration
  def self.up
    create_table :testimonials do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "name", :string, :limit => 128
      t.column "company", :string, :limit => 128
      t.column "location", :string, :limit => 128
      t.column "comment", :text
    end
  end

  def self.down
    drop_table :testimonials
  end
end

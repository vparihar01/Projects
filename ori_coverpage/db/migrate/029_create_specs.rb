class CreateSpecs < ActiveRecord::Migration
  def self.up
    create_table :specs do |t|                
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "name", :string, :limit => 150, :default => "", :null => false
      t.column "is_enabled", :boolean, :default => false, :null => false
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "contact_name", :string, :limit => 32, :default => "", :null => false
      t.column "contact_email", :string, :limit => 96, :default => "", :null => false
      t.column "contact_telephone", :string, :limit => 96, :default => "", :null => false
      t.column "customization", :text
      t.column "subjectheadings", :string, :limit => 32
      t.column "callnumbers", :string, :limit => 32
      t.column "capitalization", :string, :limit => 32
      t.column "nonfiction", :string, :limit => 32
      t.column "individualbio", :string, :limit => 32
      t.column "collectivebio", :string, :limit => 32
      t.column "fiction", :string, :limit => 32
      t.column "story", :string, :limit => 32
      t.column "easy", :string, :limit => 32
      t.column "reference", :string, :limit => 32
      t.column "include_kits", :boolean, :default => false, :null => false
      t.column "cards", :string, :limit => 32
      t.column "pockets", :string, :limit => 32
      t.column "labels", :string, :limit => 32
      t.column "arlabels", :string, :limit => 32
      t.column "rclabels", :string, :limit => 32
      t.column "include_disk", :boolean, :default => false, :null => false
      t.column "mediaformat", :string, :limit => 32
      t.column "mediatype", :string, :limit => 32
      t.column "recordformat", :string, :limit => 32
      t.column "disksoftware", :string, :limit => 32
      t.column "include_labels", :boolean, :default => false, :null => false
      t.column "symbology", :string, :limit => 32
      t.column "location", :string, :limit => 32
      t.column "position", :string, :limit => 32
      t.column "orientation", :string, :limit => 32
      t.column "libraryname", :string, :limit => 32
      t.column "startnumber", :string, :limit => 32
      t.column "endnumber", :string, :limit => 32
      t.column "include_tests", :boolean, :default => false, :null => false
      t.column "include_readinglabels", :boolean, :default => false, :null => false
    end
  end

  def self.down
    drop_table :specs
  end
end

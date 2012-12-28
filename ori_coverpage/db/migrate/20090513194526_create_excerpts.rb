class CreateExcerpts < ActiveRecord::Migration
  def self.up
    create_table :excerpts do |t|
      t.integer  :title_id, :limit => 11
      t.string   :filename
      t.string   :content_type
      t.integer  :size, :limit => 11
      t.integer  :ipaper_id
      t.string   :ipaper_access_key
      t.timestamps
    end
  end

  def self.down
    drop_table :excerpts
  end
end

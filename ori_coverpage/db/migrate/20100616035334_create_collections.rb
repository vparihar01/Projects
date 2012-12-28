class CreateCollections < ActiveRecord::Migration
  def self.up
    add_column :products, :collection_id, :integer
    create_table :collections do |t|
      t.column :name, :string
      # t.column :description, :text
      # t.column :released_on, :date
      t.timestamps
    end
    Assembly.all.each do |a|
      c = Collection.create(:name => a.name)
      # c = Collection.create(:name => a.name, :description => a.description, :released_on => a.available_on)
      a.titles.each do |t|
        t.update_attribute(:collection_id, c.id)
      end
    end
  end

  def self.down
    remove_column :products, :collection_id
    drop_table :collections
  end
end

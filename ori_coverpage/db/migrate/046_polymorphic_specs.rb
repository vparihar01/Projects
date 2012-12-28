class PolymorphicSpecs < ActiveRecord::Migration
  def self.up
    add_column :specs, :specable_type, :string
    rename_column :specs, :user_id, :specable_id
    remove_column :specs, :is_enabled
    remove_column :carts, :spec_id

    execute("update specs s, users u set s.specable_type = 'User' where s.specable_id = u.id and s.specable_type is null")
  end

  def self.down
    remove_column :specs, :specable_type
    rename_column :specs, :specable_id, :user_id
    add_column :specs, :is_enabled, :boolean, :default => false, :null => false   
    add_column :carts, :spec_id, :integer
  end
end

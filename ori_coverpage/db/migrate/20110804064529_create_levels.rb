class CreateLevels < ActiveRecord::Migration
  def self.up
    create_table :levels do |t|
      t.column :name, :string
      t.column :abbreviation, :string, :limit => 4
      t.column :is_visible, :boolean, :default => 0
      t.timestamps
    end
    min = Product.minimum(:level_min)
    max = Product.maximum(:level_max)
    APP_GRADES.each do |k,v|
      values = "#{k+2}, '#{v['value']}', '#{v['onix']}', #{k >= min && k <= max}, NOW(), NOW()"
      execute "INSERT INTO `levels` (id, name, abbreviation, is_visible, created_at, updated_at) VALUES (#{values})"
    end
  end

  def self.down
    drop_table :levels
  end
end

class AddStatusChangeableTypeToStatusChange < ActiveRecord::Migration
  def self.up
    add_column :status_changes, :status_changeable_type, :string
    StatusChange.all.each do |statuschange|
      statuschange.update_attribute(:status_changeable_type, 'LineItemCollection')
    end
    rename_column :status_changes, :sale_id, :status_changeable_id
  end

  def self.down
    StatusChange.all.each do |statuschange|
      statuschange.destroy if statuschange.status_changeable_type != 'LineItemCollection'
    end
    remove_column :status_changes, :status_changeable_type
    rename_column :status_changes, :status_changeable_id, :sale_id
  end
end

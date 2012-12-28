class RenameSectionColumn < ActiveRecord::Migration
  def self.up
    rename_column :pages, :section, :layout
  end

  def self.down
    rename_column :pages, :layout, :section
  end
end

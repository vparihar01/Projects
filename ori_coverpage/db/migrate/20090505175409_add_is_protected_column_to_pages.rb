class AddIsProtectedColumnToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :is_protected, :boolean, :default => false, :null => false
    %w(about privacy terms help prices shipping returns god).each do |path|
      page = Page.find_by_path(path)
      page.update_attribute(:is_protected, true) unless page.nil?
    end
  end

  def self.down
    remove_column :pages, :is_protected
  end
end

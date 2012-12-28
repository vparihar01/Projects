class CreateFormats < ActiveRecord::Migration
  def self.up
    create_table :formats do |t|
      t.string :name
      t.string :form
      t.string :detail
      t.boolean :is_default
      t.boolean :is_pdf
      t.boolean :is_virtual
      t.boolean :is_processed
      t.integer :units, :limit => 2, :default => 1, :null => false
      t.timestamps
    end
    [{:name => "Hardcover", :form => "Hardcover", :detail => "Library binding", :is_processed => true, :is_default => true, :is_pdf => false, :is_virtual => false, :units => 1}, {:name => "PDF", :form => "Electronic", :detail => "Adobe PDF", :is_processed => false, :is_default => false, :is_pdf => true, :is_virtual => true, :units => 1}, {:name => "Paperback", :form => "Paperback", :detail => "Trade paperback", :is_processed => false, :is_default => false, :is_pdf => false, :is_virtual => false, :units => 1}, {:name => "Hardcover + PDF", :form => nil, :detail => nil, :is_processed => true, :is_default => false, :is_pdf => false, :is_virtual => false, :units => 2}].each do |format|
      execute("INSERT INTO formats (name, form, detail, is_default, is_pdf, is_virtual, is_processed, units) VALUES ('#{format[:name]}', '#{format[:form]}', '#{format[:detail]}', '#{format[:is_default]}', '#{format[:is_pdf]}', '#{format[:is_virtual]}', '#{format[:is_processed]}', '#{format[:units]}')")
    end
  end

  def self.down
    drop_table :formats
  end
end

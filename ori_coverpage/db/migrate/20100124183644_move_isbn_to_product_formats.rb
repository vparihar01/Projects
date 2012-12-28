class MoveIsbnToProductFormats < ActiveRecord::Migration
  def self.up
    change_column :product_formats, :price, :decimal, :precision => 11, :scale => 2, :default => '0', :null => false
    change_column :product_formats, :price_list, :decimal, :precision => 11, :scale => 2, :default => '0', :null => false
    add_column :product_formats, :isbn, :string
    add_index :product_formats, :isbn
    default_format_id = 1
    pdf_format_id = 2
    Product.all.each do |product|
      # create default product format regardless of data
      pf_data = {:product_id => product.id, :format_id => default_format_id}
      pf = ProductFormat.find_or_create_by_product_id_and_format_id(pf_data)
      pf.update_attribute(:isbn, product.isbn)
      # create ebook product only if eisbn defined
      unless product.eisbn.blank?
        pf_data = {:product_id => product.id, :format_id => pdf_format_id}
        pf = ProductFormat.find_or_create_by_product_id_and_format_id(pf_data)
        pf.update_attribute(:isbn, product.eisbn)
      end
    end
    remove_column :products, :isbn
    remove_column :products, :eisbn
    remove_column :products, :binding_type
  end

  def self.down
    change_column :product_formats, :price, :decimal, :precision => 11, :scale => 2, :default => nil, :null => true
    change_column :product_formats, :price_list, :decimal, :precision => 11, :scale => 2, :default => nil, :null => true
    add_column :products, :isbn, :string
    add_column :products, :eisbn, :string
    add_column :products, :binding_type, :string, :limit => 32
    default_format_id = 1
    pdf_format_id = 2
    ProductFormat.where("format_id = ?", default_format_id).all.each do |pf|
      pf.product.update_attributes(:isbn => pf.isbn, :binding_type => pf.binding_type)
    end
    ProductFormat.where("format_id = ?", pdf_format_id).all.each do |pf|
      pf.product.update_attribute(:eisbn, pf.isbn)
    end
    remove_index :product_formats, :isbn
    remove_column :product_formats, :isbn
    remove_column :product_formats, :binding_type
  end
end

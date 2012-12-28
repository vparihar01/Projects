class ProductBundles < ActiveRecord::Migration
  def self.up
    create_table "bundles_products", :id => false, :force => true do |t|
      t.column "bundle_id",  :integer
      t.column "product_id", :integer
    end

    create_table "discounts", :force => true do |t|
      t.column "name",        :string
      t.column "code",        :string
      t.column "amount",      :decimal,  :precision => 6, :scale => 2, :default => 0.0
      t.column "percent",     :boolean
      t.column "start_on",    :date
      t.column "end_on",      :date
      t.column "type",        :string,                                 :default => "Coupon"
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
    end
    
    add_column :line_item_collections, :discount_id, :integer
    add_column :line_item_collections, :discount_amount, :decimal,  :precision => 6, :scale => 2, :default => 0.0
    add_column :line_item_collections, :discount_code, :string
  end

  def self.down
    drop_table :bundles_products
    drop_table :discounts
    remove_column :line_item_collections, :discount_id
    remove_column :line_item_collections, :discount_amount
    remove_column :line_item_collections, :discount_code
  end
end

namespace :email do
  
  desc "Export catalog requests and email customer service"
  task(:catalog_requests => :environment) do
    require 'fastercsv'
    table_name = 'catalog_requests'
    file_path = Rails.root.join("protected", "#{table_name}.csv")
    records = CatalogRequest.where("is_processed = ?", false).order("created_at DESC").all
    if records.any?
      FasterCSV.open(file_path, "w", {:row_sep => "\n", :force_quotes => true}) do |csv|
        csv << %w(id date name attention street suite city state postal_code country)
        records.each do |x|
          csv << [x.id,x.created_at,x.address.name,x.address.attention,x.address.street,x.address.suite,x.address.city,x.address.zone_name,x.address.postal_code_name,x.address.country_name]
          x.update_attribute(:is_processed, true)
        end 
      end
      puts "Sending #{table_name} (#{records.size} records)..."
      NotificationMailer.catalog_requests.deliver
    else
      puts "No new #{table_name} found..."
    end
  end
  
  desc "Export orders and email customer service"
  task(:orders => :environment) do
    require 'fastercsv'
    table_name = 'orders'
    file_path = Rails.root.join("protected", "#{table_name}.csv")
    records = Sale.includes(:ship_address, :bill_address).where("line_item_collections.completed_at >= ? and line_item_collections.completed_at < ?", (Date.today-1).to_s, (Date.today).to_s).order("line_item_collections.completed_at").all
    if records.any?
      FasterCSV.open(file_path, "w", {:row_sep => "\n", :force_quotes => true}) do |csv|
        csv << %w(id amount user_id shipping_amount shipping_method tax payment_method comments completed_at processing_amount ship_name ship_attention ship_street ship_suite ship_city ship_state ship_postal_code ship_country bill_name bill_attention bill_street bill_suite bill_city bill_state bill_postal_code bill_country)
        records.each do |x|
          # TODO: shipping method description -- need constant. see also 'fetch_rate_list' method in checkout controller.
          csv << [x.id, x.amount, x.user_id, x.shipping_amount, (x.shipping_method == '03' ? 'UPS Ground' : x.shipping_method), x.tax, x.payment_method, x.comments, x.completed_at, x.processing_amount, x.ship_address.name, x.ship_address.attention, x.ship_address.street, x.ship_address.suite, x.ship_address.city, x.ship_address.zone_name, x.ship_address.postal_code_name, x.ship_address.country_name, x.bill_address.name, x.bill_address.attention, x.bill_address.street, x.bill_address.suite, x.bill_address.city, x.bill_address.zone_name, x.bill_address.postal_code_name, x.bill_address.country_name]
        end 
      end
      puts "Sending #{table_name} (#{records.size} records)..."
      NotificationMailer.orders.deliver
    else
      puts "No new #{table_name} found..."
    end
  end
  
  desc "Export line items and email customer service"
  task(:line_items => :environment) do
    require 'fastercsv'
    table_name = 'line_items'
    file_path = Rails.root.join("protected", "#{table_name}.csv")
    records = LineItem.includes(:line_item_collection).where("line_item_collections.completed_at >= ? and line_item_collections.completed_at < ?", (Date.today-1).to_s, (Date.today).to_s).all
    if records.any?
      FasterCSV.open(file_path, "w", {:row_sep => "\n", :force_quotes => true}) do |csv|
        csv << %w(id order_id product_id product_name isbn format quantity unit_amount total_amount)
        records.each do |x|
          csv << [x.id, x.line_item_collection_id, x.product_id, x.product_name, x.product_format.isbn, x.format, x.quantity, x.unit_amount, x.total_amount]
        end 
      end
      puts "Sending #{table_name} (#{records.size} records)..."
      NotificationMailer.line_items.deliver
    else
      puts "No new #{table_name} found..."
    end
  end
  
  desc "Export specs and email customer service"
  task(:specs => :environment) do
    require 'fastercsv'
    table_name = 'specs'
    file_path = Rails.root.join("protected", "#{table_name}.csv")
    records = Sale.includes(:spec).where("line_item_collections.completed_at >= ? and line_item_collections.completed_at < ?", (Date.today-1).to_s, (Date.today).to_s).order("line_item_collections.completed_at").all
    size = 0
    if records.any?
      FasterCSV.open(file_path, "w", {:row_sep => "\n", :force_quotes => true}) do |csv|
        csv << %w(id order_id name contact_name contact_email contact_telephone customization subjectheadings callnumbers capitalization nonfiction individualbio collectivebio fiction story easy reference include_kits cards pockets labels arlabels rclabels include_disk mediaformat mediatype recordformat disksoftware include_labels symbology location position orientation libraryname startnumber endnumber include_tests include_readinglabels)
        records.each do |x|
          unless x.spec.nil?
            csv << [x.spec.id, x.id, x.spec.name, x.spec.contact_name, x.spec.contact_email, x.spec.contact_telephone, x.spec.customization, x.spec.subjectheadings, x.spec.callnumbers, x.spec.capitalization, x.spec.nonfiction, x.spec.individualbio, x.spec.collectivebio, x.spec.fiction, x.spec.story, x.spec.easy, x.spec.reference, x.spec.include_kits, x.spec.cards, x.spec.pockets, x.spec.labels, x.spec.arlabels, x.spec.rclabels, x.spec.include_disk, x.spec.mediaformat, x.spec.mediatype, x.spec.recordformat, x.spec.disksoftware, x.spec.include_labels, x.spec.symbology, x.spec.location, x.spec.position, x.spec.orientation, x.spec.libraryname, x.spec.startnumber, x.spec.endnumber, x.spec.include_tests, x.spec.include_readinglabels]    
            size += 1
          end
        end 
      end
    end
    if size > 0
      puts "Sending #{table_name} (#{size} records)..."
      NotificationMailer.specs.deliver
    else
      puts "No new #{table_name} found..."
    end
  end
  
  desc "Export catalog requests, orders, line_items, specs and email customer service"
  task(:nightly_files => [:catalog_requests, :orders, :line_items, :specs])
    
end
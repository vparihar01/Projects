namespace :load do

  desc "Import all data"
  task :all => :environment do
    require 'importer'
  
    [
      [ 'sales_teams', 'sales_teams.mer', {} ],
      [ 'sales_zones', 'sales_zones.mer', {} ],
      [ 'countries', 'countries.mer', { 'description' => 'name' } ],
      [ 'zones', 'zones.mer', { 'zone_code' => 'code' } ]
    ].each do |data_set|
      Importer.import_file(data_set[1], data_set[0], data_set[2], true)
    end
  
    Importer.import_file('contacts.mer', 'users', { 'telephone' => 'phone' }, true) do |data|
      data[4] = data[4].downcase.gsub(/ /, '_').camelize
      Importer.map_data(data)
    end
  
    Importer.import_team_members('salereps.mer', true)
    Importer.import_postal_codes('postalcodes.mer', true)
    Importer.import_addresses('addresses.mer', true)
    Importer.import_transactions('posted_trans.csv', true)
    Importer.import_posted_transaction_lines('posted_tran_lines.mer', true)
    Importer.import_sales_targets('saletargets.mer', true)
    Importer.import_products('products.csv', true)
    Importer.import_testimonials('testimonials.mer', true)
    Importer.import_links(true)
    Importer.import_editorial_reviews(true)
    Importer.import_file('faqs.csv', :faqs, {}, true)
    Importer.import_contributors(true)
    Importer.import_file('downloads.csv', :downloads, {}, true)
  end

  desc "Update products description data"
  task :update_products_description => :environment do
    require 'importer'
    Importer.update_products_description
  end

  desc "Import products data"
  task :products => :environment do
    require 'importer'
    Importer.import_products('products.csv', true)
  end

  desc "Import testimonials data"
  task :testimonials => :environment do
    require 'importer'

    Importer.import_testimonials('testimonials.mer', true)
  end

  desc "Import links data"
  task :links => :environment do
    require 'importer'

    Importer.import_links(true)
  end

  desc "Import editorial reviews data"
  task :editorial_reviews => :environment do
    require 'importer'

    Importer.import_editorial_reviews(true)
  end    

  desc "Import faqs data"
  task :faqs => :environment do
    require 'importer'
    Importer.import_file('faqs.csv', :faqs, {}, true)
  end

  desc "Import contributors data"
  task :contributors => :environment do
    require 'importer'

    Importer.import_contributors(true)
  end

  desc "Import downloads data"
  task :downloads => :environment do
    require 'importer'
    Importer.import_file('downloads.csv', :downloads, {}, true)
  end

  desc "Import categories data"
  task :categories => :environment do
    require 'importer'
    Importer.import_file('categories.csv', :categories, {}, true)
  end  

  desc 'Import update.csv file to update products. File should have two or more columns. First column is the match column (eg, id). Other columns contain data used in update (eg, author). NB: All columns must be in products table (ISBN is in product_formats table and thus can\'t be updated using this task).'
  task :update_products => :environment do
    require 'importer'
    Importer.update_table('update.csv', :products, {})
  end

end

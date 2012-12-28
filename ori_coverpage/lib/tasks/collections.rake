namespace :collections do

  desc "Reassign products from one collection to another. Required: source_id, target_id. Options: debug, verbose."
  task :reassign => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug ? true : Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    source_id = Coverpage::Utils.impose_requirement(ENV, 'source_id')
    target_id = Coverpage::Utils.impose_requirement(ENV, 'target_id')
    Coverpage::Utils.print_variable(%w(debug verbose source_id target_id), binding) if verbose
    source_collection = Collection.find(source_id)
    target_collection = Collection.find(target_id)
    puts "Reassigning products: '#{source_collection.name}' (#{source_collection.id}) -> '#{target_collection.name}' (#{target_collection.id})..." if verbose
    target_collection.products << source_collection.products unless debug
  end

  desc "Assign products to collection. Required: product_id=['1000,1001,1002'], collection_id=[10]. Optional: verbose=[TRUE|false], debug=[true|FALSE]."
  task :assign_products => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug ? true : Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    collection_id = Coverpage::Utils.impose_requirement(ENV, 'collection_id')
    product_id = Coverpage::Utils.str_to_array(ENV['product_id'])
    Coverpage::Utils.print_variable(%w(debug verbose product_id collection_id), binding) if verbose
    collection = Collection.find(collection_id.to_i)
    products = Title.where("id IN (?)", product_id).all
    Coverpage::Utils.print_collection(collection) if verbose
    if products.any?
      collection.products << products unless debug
    else
      puts "  No products found to assign."
    end
  end
  
  desc "Create a collection based on an assembly. Assembly (and its titles) are assigned to new collection. Required: assembly_id=[10000]. Optional: verbose=[TRUE|false]."
  task :create_from_assembly => :environment do
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true)
    assembly_id = Coverpage::Utils.impose_requirement(ENV, 'assembly_id')
    Coverpage::Utils.print_variable(%w(verbose assembly_id), binding) if verbose
    Collection.create_from_assembly(assembly_id.to_i)
  end
  
  desc "Assign assembly (and its titles) to collection. Required: assembly_id=[10000], collection_id=[10]. Optional: verbose=[TRUE|false], debug=[true|FALSE]."
  task :assign_assembly => [:environment] do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    assembly_id = Coverpage::Utils.impose_requirement(ENV, 'assembly_id')
    collection_id = Coverpage::Utils.impose_requirement(ENV, 'collection_id')
    Coverpage::Utils.print_variable(%w(debug verbose assembly_id collection_id), binding) if verbose
    assembly = Assembly.find(assembly_id.to_i)
    collection = Collection.find(collection_id.to_i)
    puts "Assembly: '#{assembly.name}' (#{assembly.id})" if verbose
    puts "Collection: '#{collection.name}' (#{collection.id})" if verbose
    collection.assign_assembly(assembly) unless debug
  end
  
  desc "Ensure assembly titles are also assigned to collection. Required: id. Options: debug, verbose."
  task :update_titles_per_assemblies=> :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug ? true : Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    id = Coverpage::Utils.impose_requirement(ENV, 'id')
    Coverpage::Utils.print_variable(%w(debug verbose id), binding) if verbose
    collection = Collection.find(id)
    collection.update_titles_per_assemblies
  end
  
  desc "Update collection's release date using oldest title and description using data from similarly named assembly. Optional: collection_id, verbose, debug."
  task :update => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    collection_id = Coverpage::Utils.str_to_array(ENV['collection_id'])
    Coverpage::Utils.print_variable(%w(debug verbose collection_id), binding) if verbose
    if collection_id.any?
      collections = Collection.where("id IN (?)", collection_id).all
    else
      collections = Collection.all
    end
    collections.each do |collection|
      puts "#{collection.id} | #{collection.name} | #{collection.released_on}" if verbose
      if collection.products.any?
        first_pub_date = collection.products.first(:order => 'available_on ASC').available_on
        data = {:released_on => first_pub_date}
        puts "  #{data.inspect}" if debug
        unless debug
          collection.update_attribute(:released_on, first_pub_date) unless first_pub_date.blank?
        end
      else
        puts "  Skip: Collection has no products" if verbose
      end
      if assembly = Assembly.find_by_name(collection.name)
        data = {:description => assembly.description}
        puts "  #{data.inspect}" if debug
        unless debug
          collection.update_attribute(:description, assembly.description) unless assembly.description.blank?
        end
      else
        puts "Skip: No matching assembly found" if verbose
      end
    end
  end
  
  desc "List collections that have no products."
  task :is_empty => :environment do
    puts "No assigned products:"
    Collection.order('name').all.each do |collection|
      unless collection.products.count > 0
        Coverpage::Utils.print_collection(collection)
      end
    end
  end
  
end


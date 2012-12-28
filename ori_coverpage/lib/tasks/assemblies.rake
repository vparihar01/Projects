namespace :assemblies do

  desc "Update assembly prices. Command line parameters: 'assembly_id=[1000|1001...]', 'verbose=[TRUE|false]', 'debug=[true|FALSE]'."
  task :update_prices => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    assembly_id = Coverpage::Utils.str_to_array(ENV['assembly_id'])
    Coverpage::Utils.print_variable(%w(debug verbose assembly_id), binding) if verbose
    if assembly_id.any?
      assemblies = Assembly.where("id IN (?)", assembly_id).all
    else
      assemblies = Assembly.all
    end
    assemblies.each do |assembly|
      puts "Calculating prices for '#{assembly.name}' (#{assembly.id})..." if verbose
      assembly.calculate_price unless debug
    end
  end
  
  desc "Assign titles to assembly. Command line parameters: 'title_id=[1000|1001...]', 'assembly_id=1000', 'verbose=[TRUE|false]', 'debug=[true|FALSE]'."
  task :assign_titles => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    assembly_id = Coverpage::Utils.impose_requirement(ENV, 'assembly_id')
    title_id = Coverpage::Utils.str_to_array(ENV['title_id'])
    Coverpage::Utils.print_variable(%w(debug verbose title_id assembly_id), binding) if verbose
    titles = Title.where("id IN (?)", title_id).all
    assembly = Assembly.find(assembly_id.to_i)
    # update assembly assignments
    puts "Assembly: '#{assembly.name}' (#{assembly.id})" if verbose
    assembly.assign_titles(titles)
  end
  
  desc "Copy titles from source assembly to target assembly. Source retains titles too. Required: source_id=[1040], target_id=[1230]. Optional: verbose=[TRUE|false]."
  task :copy_titles => [:environment] do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    source_id = Coverpage::Utils.impose_requirement(ENV, 'source_id')
    target_id = Coverpage::Utils.impose_requirement(ENV, 'target_id')
    Coverpage::Utils.print_variable(%w(debug verbose source_id target_id), binding) if verbose

    source = Assembly.find(source_id.to_i)
    target = Assembly.find(target_id.to_i)

    # update assembly assignments
    puts "Source: '#{source.name}' (#{source.id})" if verbose
    puts "Target: '#{target.name}' (#{target.id}) \n\n" if verbose
    puts "Copying assembly assignments (#{source.id} => #{target.id})..." if verbose
    target.assign_titles(source.titles)
  end
  
  desc "Copy titles from old assembly to new assembly of same name. If name not given, do so for all assemblies in specified season. Old assembly retains titles too. Optional: debug, verbose, name, season."
  task :copy_titles_from_predecessor => [:environment] do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    name = ENV['name'].blank? ? nil : ENV['name']
    season = ENV['season'].to_s.downcase
    Coverpage::Utils.print_variable(%w(debug verbose name season), binding) if verbose
    assemblies = get_assemblies_by_name_or_season(name, season)
    assemblies.each do |assembly|
      assembly.copy_titles_from_predecessor(:debug => debug, :verbose => verbose)
    end
  end
  
  desc "Copy categories from old assembly to new assembly of same name. If name not given, do so for all assemblies in specified season. Optional: debug, verbose, name, season."
  task :copy_categories_from_predecessor => [:environment] do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    name = ENV['name'].blank? ? nil : ENV['name']
    season = ENV['season'].to_s.downcase
    Coverpage::Utils.print_variable(%w(debug verbose name season), binding) if verbose
    assemblies = get_assemblies_by_name_or_season(name, season)
    assemblies.each do |assembly|
      assembly.copy_categories_from_predecessor(:debug => debug, :verbose => verbose)
    end
  end
  
  def get_assemblies_by_name_or_season(name, season)
    unless name
      case season
      when 'new'
        meth = 'newly_available'
      when 'recent'
        meth = 'recently_available'
      when 'upcoming'
        meth = 'upcoming'
      else
        puts "! Error: Unknown season '#{season}'"
        meth = nil
        exit 1
      end
    end
    if name
      if assembly = Assembly.where("name = ? AND available_on IS NOT NULL", name).order('available_on DESC').first
        assemblies = [assembly]
      else
        FEEDBACK.error("Assembly not found '#{name}'")
        assemblies = []
      end
    else
      assemblies = Assembly.send(meth)
    end
    assemblies
  end

  desc "Assign collection titles to assembly. Required: assembly_id=[10000], collection_id=[10]. Optional: verbose=[TRUE|false], debug=[true|FALSE]."
  task :assign_collection_titles => [:environment] do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    assembly_id = Coverpage::Utils.impose_requirement(ENV, 'assembly_id')
    collection_id = Coverpage::Utils.impose_requirement(ENV, 'collection_id')
    Coverpage::Utils.print_variable(%w(debug verbose assembly_id collection_id), binding) if verbose

    # update assembly assignments
    assembly = Assembly.find(assembly_id.to_i)
    collection = Collection.find(collection_id.to_i)
    puts "Assembly: '#{assembly.name}' (#{assembly.id})" if verbose
    puts "Collection: '#{collection.name}' (#{collection.id}) \n\n" if verbose
    puts "Assigning collection titles to assembly..." if verbose
    assembly.assign_titles(collection.products.where("type = 'Title'"))
  end
  
  desc "Assign BISAC to assembly using BISAC of first title in assembly. Command line parameters: 'assembly_id=[1000|1001...]', 'verbose=[TRUE|false]', 'debug=[true|FALSE]'."
  task :assign_bisac => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    assembly_id = Coverpage::Utils.str_to_array(ENV['assembly_id'])
    Coverpage::Utils.print_variable(%w(debug verbose assembly_id), binding) if verbose
    if assembly_id.any?
      assemblies = Assembly.where("id IN (?)", assembly_id).all
    else
      assemblies = Assembly.all
    end
    assemblies.each do |assembly|
      puts "Assigning Bisac to '#{assembly.name}' (#{assembly.id})..." if verbose
      if assembly.bisac_subjects.any?
        puts "  Skip: Assembly already has Bisacs assigned" if verbose
        next
      end
      if title = assembly.titles.first
        if title.bisac_subjects.any? && main_bisac_subject_id = title.bisac_assignments.first.bisac_subject_id
          ba_data = {:product_id => assembly.id, :bisac_subject_id => main_bisac_subject_id}
          puts "  #{ba_data.inspect}" if verbose
          unless debug
            ba = BisacAssignment.find_or_create_by_product_id_and_bisac_subject_id(ba_data)
            log(ba.errors.full_messages) if ba.errors.any?
          end
        else
          puts "  Skip: First title has no Bisac" if verbose
        end
      else
        puts "  Skip: Assembly has no titles" if verbose
      end
    end
  end
  
  desc "Set date available to that of latest title in assembly. If assembly_id not given, update all assemblies with no date. Optional: assembly_id=[1000|1001...]."
  task :set_date => :environment do
    assembly_id = Coverpage::Utils.str_to_array(ENV['assembly_id'])
    Coverpage::Utils.print_variable(%w(assembly_id), binding)
    if assembly_id.any?
      assemblies = Assembly.where("id IN (?)", assembly_id)
    else
      assemblies = Assembly.where("available_on is null or available_on = ''")
    end
    assemblies.each do |assembly|
      assembly.set_date_to_first_available_title
    end
  end
  
  desc "List assemblies that have no titles."
  task :is_empty => :environment do
    puts "No assigned titles:"
    Assembly.order('name').all.each do |assembly|
      unless assembly.titles.count > 0
        Coverpage::Utils.print_product(assembly)
      end
    end
  end
  
  desc "Perform suggested similarities. Optional: assembly_id, debug, verbose, force."
  task :perform_suggested_similarities => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    force = Coverpage::Utils.str_to_boolean(ENV['force'])
    assembly_id = Coverpage::Utils.str_to_array(ENV['assembly_id'])
    Coverpage::Utils.print_variable(%w(debug verbose force assembly_id), binding) if verbose
    if assembly_id.any?
      assemblies = Assembly.where("id IN (?)", assembly_id).all
    else
      assemblies = Assembly.all
    end
    assemblies.each do |assembly|
      assembly.suggested_similarities.each do |another_assembly|
        assembly.similar_to(another_assembly, :debug => debug, :verbose => verbose, :force => force)
      end
    end
  end

  desc "Perform suggested replacements. Optional: assembly_id, debug, verbose, force."
  task :perform_suggested_replacements => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true) )
    force = Coverpage::Utils.str_to_boolean(ENV['force'])
    assembly_id = Coverpage::Utils.str_to_array(ENV['assembly_id'])
    Coverpage::Utils.print_variable(%w(debug verbose force assembly_id), binding) if verbose
    if assembly_id.any?
      assemblies = Assembly.where("id IN (?)", assembly_id).all
    else
      assemblies = Assembly.all
    end
    assemblies.each do |assembly|
      assembly.replace_with(assembly.suggested_replacement, :debug => debug, :verbose => verbose, :force => force)
    end
  end

  desc "List assemblies to find replacements. Options: verbose."
  task :replacements => :environment do
    verbose = Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true)
    columns = 4; n_id = 5; n_name = 50; n_count = 3; n_date = 10; n_status = 4
    total = n_id + n_name + n_count + n_date + n_status
    puts sprintf("%-*s | %-*s | %*s | %*s | %*s", n_id, "ID", n_name, "Name", n_count, "#", n_date, "Date", n_status, "Stat") if verbose
    separator = "-" * (total + columns * 3)
    puts separator if verbose
    prev = nil
    solve = []
    Assembly.includes(:product_formats).where('products.available_on <= CURRENT_DATE').order('name ASC, available_on DESC, proprietary_id DESC').all.each do |assembly|
      puts sprintf("%-*d | %-*s | %*d | %*s | %*s", n_id, assembly.id, n_name, assembly.name.split(//)[0..(n_name-1)], n_count, assembly.titles.count, n_date, assembly.available_on.to_s, n_status, assembly.default_format.status) if verbose
      # [older, newer] -- prev is the newer since we're sorting available_on desc
      # NB: we're only checking the status of the default_format
      #     we're assuming other formats have the same status
      solve << [assembly, prev] if prev.try(:name) == assembly.name && prev.default_format.status == ProductFormat::ACTIVE_STATUS_CODE
      prev = assembly unless prev.try(:name) == assembly.name
    end
    puts separator if verbose
    solve.each {|a| puts "rake assembly:replace old=#{a[0].id} new=#{a[1].id}"}
  end
  
  desc "Replace one assembly with another. Specify new and old by product id. Required: old, new. Optional: debug, verbose, force."
  task :replace => :environment do
    # Assumption: new product has same formats as old product
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['debug'], :default => true) )
    force = Coverpage::Utils.str_to_boolean(ENV['force'], :default => false)
    old_id = Coverpage::Utils.impose_requirement(ENV, 'old')
    new_id = Coverpage::Utils.impose_requirement(ENV, 'new')
    Coverpage::Utils.print_variable(%w(debug verbose force old_id new_id), binding) if verbose
    old_assembly = Assembly.find(old_id)
    new_assembly = Assembly.find(new_id)
    old_assembly.replace_with(new_assembly, :debug => debug, :verbose => verbose, :force => force)
  end
  
  desc "Delete related product assignment. Update product format status to match that of its titles. Required: id. Optional: debug, verbose."
  task :unreplace => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['debug'], :default => true) )
    id = Coverpage::Utils.impose_requirement(ENV, 'id')
    Coverpage::Utils.print_variable(%w(debug verbose id), binding) if verbose
    assembly = Assembly.find(id)
    assembly.unreplace(:debug => debug, :verbose => verbose)
    assembly.match_titles_status(:debug => debug, :verbose => verbose, :force => true)
  end

  desc "Set assembly status to that of its constituent titles. Options: debug, ids."
  task :match_titles_status => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    if ENV['ids'].blank?
      ids = nil
      assemblies = Assembly
    else
      ids = ENV['ids'].split(',').map{|i| i.strip}
      assemblies = Assembly.where("id IN (?)", ids)
    end
    Coverpage::Utils.print_variable(%w(debug verbose ids), binding)
    assemblies.all.each do |assembly|
      assembly.match_titles_status(:debug => debug)
    end
  end
  
end

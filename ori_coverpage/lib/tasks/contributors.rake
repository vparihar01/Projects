namespace :contributors do

  desc "Check that contributor matches product's author. Options: debug, verbose, fix."
  task :check => [:environment] do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => false))
    ids = ENV['ids'].blank? ? [] : ENV['ids'].split(',').map{|i| i.strip}
    fix = Coverpage::Utils.str_to_boolean(ENV['fix'], :default => false)
    Coverpage::Utils.print_variable(%w(debug verbose ids fix), binding)
    if ids.any?
      contributors = Contributor.where("id IN (?)", ids)
    else
      contributors = Contributor
    end
    columns = 4; n_cid = 4; n_name = 22; n_pid = 5; n_author = 40
    total = n_cid + n_name + n_pid + n_author
    puts sprintf("%-*s | %-*s | %-*s | %-*s", n_cid, "ID", n_name, "Contributor Name", n_pid, "ID", n_author, "Product Author")
    separator = "-" * (total + (columns - 1) * 3)
    puts separator
    contributors.order(:name).all.each do |contributor|
      contributor.contributor_assignments.includes(:product).where("role = ?", "Author").each do |ca|
        product = ca.product
        unless /#{contributor.name}/.match(product.author)
          puts sprintf("%-*d | %-*s | %-*d | %-*s", n_cid, contributor.id, n_name, contributor.name.to_s.split(//)[0..(n_name-1)], n_pid, product.id, n_author, product.author.to_s.split(//)[0..(n_author-1)])
        end
      end
    end
    puts separator
  end

  desc "List contributors with no bio."
  task :list_missing_bios => [:environment] do
    contributors = Contributor.where("description IS NULL OR description = ''").order('name').all
    contributors.each {|contributor| puts "#{contributor.name}"}
  end
  
  desc "Merge contributor records. Source product assignments will be merged with target. Source will be destroyed. Required: source, target. Optional: debug, verbose."
  task :merge => [:environment] do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose']))
    source = Coverpage::Utils.impose_requirement(ENV, 'source')
    target = Coverpage::Utils.impose_requirement(ENV, 'target')
    Coverpage::Utils.print_variable(%w(debug verbose source target), binding) if verbose
    # task will abort if records not found
    source = Contributor.find(source)
    target = Contributor.find(target)
    # do it
    target.merge(source, :debug => debug, :verbose => verbose)
  end
  
  desc "Split contributors into two separate records if name column contains ' and '."
  task :split => [:environment] do
    # process command line parameters
    contributors = Contributor.where("name LIKE '% and %'").all
    contributors.each do |contributor|
      puts "Original: #{contributor.name} (#{contributor.id})"
      names = contributor.name.split(' and ')
      if names.size > 1
        new_name = names.shift
        puts "  Replacing name with '#{new_name}'..."
        contributor.update_attribute(:name, new_name)
        product_ids = contributor.contributor_assignments.map(&:product_id)
        names.each do |name|
          puts "  Creating new contributor '#{name}'..."
          new_contributor = Contributor.find_or_create_by_name(:name => name, :default_role => contributor.default_role, :description => contributor.description)
          product_ids.each do |id|
            puts "  Creating new assignment '#{name}', '#{id}'..."
            new_contributor.contributor_assignments.find_or_create_by_product_id_and_role(:product_id => id, :role => contributor.default_role)
          end
        end
      end
    end
  end
  
end

namespace :links do

  desc "Assign links to assemblies. Options: debug, verbose, ids."
  task :assign_assemblies => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    if ENV['ids'].blank?
      ids = nil
      links = Link
    else
      ids = ENV['ids'].split(',').map{|i| i.strip}
      links = Link.where("id IN (?)", ids)
    end
    Coverpage::Utils.print_variable(%w(debug verbose), binding) if verbose
    links.all.each do |link|
      link.assign_assemblies(:debug => debug, :verbose => verbose)
    end
  end
  
  desc "Merge link records. Source product assignments will be merged with target. Source will be destroyed. Required: source, target. Optional: debug, verbose."
  task :merge => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose']))
    source = Coverpage::Utils.impose_requirement(ENV, 'source')
    target = Coverpage::Utils.impose_requirement(ENV, 'target')
    Coverpage::Utils.print_variable(%w(debug verbose source target), binding) if verbose
    # task will abort if records not found
    source = Link.find(source)
    target = Link.find(target)
    # do it
    target.merge(source, :debug => debug, :verbose => verbose)
  end

end

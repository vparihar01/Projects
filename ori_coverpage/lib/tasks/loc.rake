namespace :loc do
  require 'loc'

  desc "Update title, specified by isbn (eg, isbn=9781602790674), using product data from LOC site. Required: isbn=[9781602790674...]. Optional: verbose=[true|FALSE], debug=[true|FALSE], force=[true|FALSE]."
  task :update_title => :environment do
    isbn = Coverpage::Utils.impose_requirement(ENV, 'isbn')
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose']) )
    force = Coverpage::Utils.str_to_boolean(ENV['force'], :default => false) # force search by isbn
    Coverpage::Utils.print_variable(%w(isbn debug verbose force), binding) if verbose
    loc = Loc.new(isbn, verbose, debug, force)
    loc.update_title
  end

  desc "Update titles using product data from LOC site. Optional: verbose=[true|FALSE], debug=[true|FALSE], force=[true|FALSE], season=[upcoming|new|recent]."
  task :update_titles => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'])
    verbose = ( debug || Coverpage::Utils.str_to_boolean(ENV['verbose']) )
    force = Coverpage::Utils.str_to_boolean(ENV['force'], :default => false) # force search by isbn
    season = ENV['season'].blank? ? '' : ENV['season'].downcase
    start_date, end_date = Coverpage::Utils.season_to_dates(ENV['season'])
    Coverpage::Utils.print_variable(%w(season start_date end_date debug verbose force), binding) if verbose
    Title.includes(:default_format).available_between(start_date, end_date).each_with_index do |t,i|
      Coverpage::Utils.print_product(t, :i => i) if verbose
      loc = Loc.new(t.default_format.isbn, verbose, debug, force)
      loc.update_title
    end
  end

end

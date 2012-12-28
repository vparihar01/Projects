namespace :permabound do
  require 'rake_utils'
  require 'permabound'

  desc "Update title, specified by isbn (eg, isbn=9781602790674), using product data from permabound site. Command line parameters: 'isbn=[9781602790674...]', 'verbose=[true|FALSE]', 'debug=[true|FALSE]'."
  task :update_title => :environment do
    isbn = RakeUtils.impose_requirement(ENV, 'isbn')
    debug = RakeUtils.str_to_boolean(ENV['debug'])
    verbose = ( debug || RakeUtils.str_to_boolean(ENV['verbose']) )
    RakeUtils.print_variable(%w(isbn), binding) if verbose
    unless t = Title.find_by_isbn(isbn)
      puts "No title found with specified ISBN (#{isbn})"
      exit 1
    end
    pb = Permabound.new(isbn, verbose, debug)
    pb.update_title
  end

  desc "Update titles using product data from permabound site. Command line parameters: 'verbose=[true|FALSE]', 'debug=[true|FALSE]', 'season=[upcoming|new|recent]'."
  task :update_titles => :environment do
    debug = RakeUtils.str_to_boolean(ENV['debug'])
    verbose = ( debug || RakeUtils.str_to_boolean(ENV['verbose']) )
    season = ENV['season'].blank? ? '' : ENV['season'].downcase
    start_date, end_date = RakeUtils.season_to_dates(ENV['season'])
    RakeUtils.print_variable(%w(season start_date end_date), binding) if verbose
    Title.includes(:default_format).available_between(start_date, end_date).each_with_index do |t,i|
      puts "#{i+1}. #{t.name}"
      pb = Permabound.new(t.default_format.isbn, verbose, debug)
      pb.update_title
    end
  end

end

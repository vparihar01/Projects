require "rake_utils"

namespace :passenger do
  desc "Restart Application. Options: debug, verbose."
  task :restart do
    debug = RakeUtils.str_to_boolean(ENV['debug'])
    verbose = (debug || RakeUtils.str_to_boolean(ENV['verbose']))
    RakeUtils.print_variable(%w(debug verbose), binding) if verbose
    FileUtils.touch(Rails.root.join("tmp/restart.txt"), :noop => debug, :verbose => verbose)
  end
end

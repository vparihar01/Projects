# config/deploy.rb
#
# a capistrano deployment for coverpage projects used by the milkfarm staff
#
# this deployment file is suitable for milkfarm's best practices and servers set up
# according to these best practices, but likely to work on other linux boxes configured
# with apache+ree+passenger
#
# the file requires deploy.yml to be present besides that should specify the target system
# and deployment related parameters. for details, please consult config/deploy.template.yml
#
# TODO: if it should happen that other parameters must be customized across various deployments,
# this file should be updated to use a DEPLOY['someparam'] and deploy.template.yml as well as the
# actual real instances of deploy.yml (across themes/deployments) should be updated to define 
# someparam: "somevalue"
#

# For more info on cap variables, see:
# /usr/lib/ruby/gems/1.8/gems/capistrano-2.0.0/lib/capistrano/recipes/deploy.rb
require "whenever/capistrano"
require "bundler/capistrano"

# load the deployment parameters
DEPLOYMENT_CONFIG = File.expand_path('../deploy.yml', __FILE__)
if File.exist?(DEPLOYMENT_CONFIG)
  # we should have a symlink if the framework is being used
  if !File.symlink?(DEPLOYMENT_CONFIG)
    Capistrano::CLI.ui.say("Capistrano deployment is configured BUT not with the Coverpage framework. Hope you know what you're doing. Anyway, waiting 10 seconds before proceeding...\nCheck your params below:\n")
    system("cat #{DEPLOYMENT_CONFIG}")
    (i=10).times do
      print "#{i}..."
      i -= 1
      sleep 1
    end
    # if the user did not interrupt, we're gonna deploy as the config/deploy.yml parameters...
  end
else
  Capistrano::CLI.ui.say("Coverpage is not configured for remote deployment.")
  Capistrano::CLI.ui.say("Configure sites, then run 'script/site enable SITE'.")
  Capistrano::CLI.ui.say("Alternately, create 'config/deploy.yml' by hand (not recommended).")
  Capistrano::CLI.ui.say("Aborting...")
  exit 1
end

# let's load the config
DEPLOY = YAML.load(File.open(DEPLOYMENT_CONFIG))

set :application, DEPLOY['application']
set :repository, DEPLOY['repository']

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, DEPLOY['deploy_to']
set :rails_env, DEPLOY['rails_env']

# set the user and group that will own the app. file permission will be set to user:group
set :user, DEPLOY['user']
set :group, DEPLOY['group']

# Set user with permissions to run the application scripts
set :runner, DEPLOY['runner']

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git
set :deploy_via, :remote_cache
set :branch, DEPLOY['branch']
# set :ssh_options, { :forward_agent => true }

# Cache svn authentication
set :scm_auth_cache, true

# Set svn username and password
set :scm_username, DEPLOY['scm_username']
set :scm_password, DEPLOY['scm_password']

# Resolve tty error (only occurs on mt dv 3.5 server):
default_run_options[:pty] = true

# Save space by only keeping last X revisions when running cleanup (default is 5)
set :keep_releases, DEPLOY['keep_releases']

# Roles, server ip address can also be used
role :app, DEPLOY['role_app']
role :web, DEPLOY['role_web']
role :db,  DEPLOY['role_db'], :primary => true

# Restart the web server once the deployment is finished
after "deploy:setup", "utils:fix_railsdir_ownership", "utils:create_shared_dirs", "utils:fix_ownerships", "utils:fix_permissions"
after "deploy", "deploy:cleanup"
after "deploy:update_code", "deploy:symlink_shared", "deploy:install_theme"
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"

#############################################################
# Utils
#############################################################

namespace :utils do

  desc "Fix ownership of the rails directory and its sub-directories"
  task :fix_railsdir_ownership, :roles => :app do
    sudo "chown -R #{user}:#{group} #{deploy_to}"
  end

  desc "Setup shared directory with subdirectories required by app"
  task :create_shared_dirs, :roles => :app do
    # tmp dirs
    run "if [ ! -d #{shared_path}/tmp/attachment_fu ]; then mkdir -p #{shared_path}/tmp/attachment_fu ; fi"
    run "if [ ! -d #{shared_path}/tmp/cache ]; then mkdir -p #{shared_path}/tmp/cache ; fi"
    run "if [ ! -d #{shared_path}/tmp/sessions ]; then mkdir -p #{shared_path}/tmp/sessions ; fi"
    run "if [ ! -d #{shared_path}/tmp/sockets ]; then mkdir -p #{shared_path}/tmp/sockets ; fi"
    run "if [ ! -d #{shared_path}/tmp/pids ]; then mkdir -p #{shared_path}/tmp/pids ; fi"
    run "if [ ! -d #{shared_path}/tmp/pdftool ]; then mkdir -p #{shared_path}/tmp/pdftool ; fi"
    run "if [ ! -d #{shared_path}/tmp/ebooks/in ]; then mkdir -p #{shared_path}/tmp/ebooks/in ; fi"
    run "if [ ! -d #{shared_path}/tmp/ebooks/out ]; then mkdir -p #{shared_path}/tmp/ebooks/out ; fi"
    run "if [ ! -d #{shared_path}/tmp/ebooks/bad ]; then mkdir -p #{shared_path}/tmp/ebooks/bad ; fi"
    run "if [ ! -d #{shared_path}/tmp/ebooks/unknown ]; then mkdir -p #{shared_path}/tmp/ebooks/unknown ; fi"
    run "if [ ! -d #{shared_path}/tmp/import ]; then mkdir -p #{shared_path}/tmp/import ; fi"
    run "if [ ! -d #{shared_path}/tmp/import/archive ]; then mkdir -p #{shared_path}/tmp/import/archive ; fi"
    # config, etc
    run "if [ ! -d #{shared_path}/config ]; then mkdir -p #{shared_path}/config ; fi"
    run "if [ ! -d #{shared_path}/images/covers/s ]; then mkdir -p #{shared_path}/images/covers/s ; fi"
    run "if [ ! -d #{shared_path}/images/covers/m ]; then mkdir -p #{shared_path}/images/covers/m ; fi"
    run "if [ ! -d #{shared_path}/images/covers/l ]; then mkdir -p #{shared_path}/images/covers/l ; fi"
    run "if [ ! -d #{shared_path}/images/spreads/s ]; then mkdir -p #{shared_path}/images/spreads/s ; fi"
    run "if [ ! -d #{shared_path}/images/spreads/m ]; then mkdir -p #{shared_path}/images/spreads/m ; fi"
    run "if [ ! -d #{shared_path}/images/spreads/l ]; then mkdir -p #{shared_path}/images/spreads/l ; fi"
    run "if [ ! -d #{shared_path}/images/gliders ]; then mkdir -p #{shared_path}/images/gliders ; fi"
    run "if [ ! -d #{shared_path}/protected/downloads ]; then mkdir -p #{shared_path}/protected/downloads ; fi"
    run "if [ ! -d #{shared_path}/protected/excerpts ]; then mkdir -p #{shared_path}/protected/excerpts ; fi"
    run "if [ ! -d #{shared_path}/protected/ebooks ]; then mkdir -p #{shared_path}/protected/ebooks ; fi"
    run "if [ ! -d #{shared_path}/flipbooks ]; then mkdir -p #{shared_path}/flipbooks ; fi"
  end

  desc "Make a copy of the configuration templates if configurations don't exist"
  task :copy_templates, :roles => :app do
    # please note, that this will make copies of the TEMPLATE files
    # you should immediately go and edit the config files, unless the examples are matching your needs
    ['newrelic.template.yml', 'authorizenet.template.yml', 'config.template.yml', 'database.template.yml', 'scribd_fu.template.yml', 'ups.template.yml', 'mailer.template.yml'].each do |template|
      config_file = template.sub('template.', '')
      run "if [ ! -f #{shared_path}/config/#{config_file} ]; then cp -p #{current_release}/config/#{template} #{shared_path}/config/#{config_file} ; fi"
    end
  end

  desc "Fix ownerships"
  task :fix_ownerships, :roles => :app do
    sudo "chown -R #{user}:#{group} #{shared_path}/log"
    sudo "sh -c 'if [ -d #{release_path} ]; then chown -R #{user}:#{group} #{release_path}/tmp/sessions ; echo \"fixed ownership on #{release_path}/tmp/sessions\" ; fi'"
    sudo "chown -R #{user}:#{group} #{shared_path}/protected/downloads"
    sudo "chown -R #{user}:#{group} #{shared_path}/protected/excerpts"
    sudo "chown -R #{user}:#{group} #{shared_path}/protected/ebooks"
  end

  desc "Fix permissions"
  task :fix_permissions, :roles => :app do
    sudo "touch #{shared_path}/log/development.log"
    sudo "touch #{shared_path}/log/production.log"
    sudo "chmod 666 #{shared_path}/log/*.log" # this fails if no *.log files are present
  end
  
  desc "Cleanup tmp directory"
  task :cleanup_tmp, :roles => :app do
    # captcha image files
    run "rm -vf #{shared_path}/tmp/*.png"
    # product data files
    run "rm -vf #{shared_path}/tmp/#{DEPLOY['theme']}-*"
  end
  
end

#############################################################
# Passenger
#############################################################

namespace :passenger do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

#############################################################
# Deployment
#############################################################

namespace :deploy do
  # Override capistrano restart, run passenger.restart instead
  %w(start restart).each { |name| task name, :roles => :app do passenger.restart end }

  desc "Symlink shared configs and asset directories on each release."
  task :symlink_shared do
    # symlink config files
    configs = ['newrelic.yml', 'authorizenet.yml', 'config.yml', 'database.yml', 'scribd_fu.yml', 'ups.yml', 'mailer.yml', 'schedule.yml', 'backup.yml']
    configs.each do |file_name|
      run "rm -f #{release_path}/config/#{file_name}"  # technically shouldn't be in repository
      run "ln -nfs #{shared_path}/config/#{file_name} #{release_path}/config/"
    end
    # symlink asset directories
    assets = ['tmp', 'public/images/covers', 'public/images/spreads', 'public/images/gliders', 'protected', 'public/flipbooks']
    assets.each do |dir_path|
      sym_path = dir_path.sub('public/', '')
      run "rm -rf #{release_path}/#{dir_path}"  # technically shouldn't be in repository
      run "ln -nfs #{shared_path}/#{sym_path} #{release_path}/#{dir_path}"
    end
  end
  
  desc "Sync asset directories."
  task :assets do
    assets = ['public/images/covers', 'public/images/spreads', 'public/images/gliders', 'public/flipbooks']
    assets.each do |dir_path|
      sym_path = dir_path.sub('public/', '')
      system "rsync -avz --exclude '.svn/' --exclude '.DS_Store' --exclude '.htaccess' --exclude 'Icon' #{dir_path}/. #{user}@#{application}.com:#{shared_path}/#{sym_path}/."
    end
  end

  desc "Install a coverpage theme."
  task :install_theme do
    Capistrano::CLI.ui.say("    preparing to install theme #{DEPLOY['theme']} remotely. remote prompt follows...")
    cmd = "cd #{current_release}; RAILS_ENV=#{rails_env} script/theme install --force #{DEPLOY['theme']}"
    run(cmd) do |ch, stream, data|
      # ch is the SSH channel for this command, used to send data
      # back to the command (e.g. ch.send_data("password\n"))
      # stream is either :out or :err, for which stream the data arrived on
      # data is a string containing data sent from the remote command
      case stream
      when :out
        Capistrano::CLI.ui.say(" ** [remote output ::] #{data}")
        case data
        when /\bpassword.*:/i
          # git is prompting for a password
          ch.send_data "#{DEPLOY['scm_password']}\n" #"#{pass}\n"
        end
      end
    end
    Capistrano::CLI.ui.say("    end of remote prompt. theme should be installed.")
  end
end

#############################################################
# Rake
#############################################################

namespace :rake do
  desc "Run a rake task on a remote server."
  # Example: cap staging rake:invoke task=export:upcoming
  task :invoke do
    run("cd #{deploy_to}/current; #{DEPLOY['remote_rake']} #{ENV['task']} RAILS_ENV=#{rails_env}")
  end
end

#############################################################
# Delayed job
#############################################################

namespace :delayed_job do
  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} script/delayed_job stop"
  end
  
  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} script/delayed_job start"
  end
  
  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} script/delayed_job restart"
  end
end

require 'bundler/capistrano'

set :application, "sportsbeat"
set :scm, :git
set :repository, "ssh://git@bitbucket.org/sportsbeat/sportsbeat-20120802.git"
set :branch, "master"
set :scm_verbose, true
set :use_sudo, false
#default_run_options[:pty] = true
ssh_options[:forward_agent] = true
set :normalize_asset_timestamps, false # set false if using rails 3.1

namespace :deploy do
  task :start do
  end

  task :stop do
  end

  # Unicorn - QUIT is a hard restart, USR2 is a graceful restart
  #task :restart, :roles => :app, :except => { :no_release => true } do
  #  run "kill -QUIT `cat #{current_path}/tmp/pids/unicorn.pid`"
  #end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "kill -USR2 `cat #{current_path}/tmp/pids/unicorn.pid`"
  end

  task :seed, :roles => :db do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} rake db:seed"
  end
end

set :shared_assets, %w{public/uploads}
set(:shared_children, shared_children + %w(tmp/sockets))

namespace :assets  do
  namespace :symlinks do
    desc "Setup application symlinks for shared assets"
    task :setup, :roles => [:app, :web] do
      shared_assets.each { |link| run "mkdir -p #{shared_path}/#{link}" }
    end

    desc "Link assets for current deploy to the shared location"
    task :update, :roles => [:app, :web] do
      shared_assets.each { |link| run "ln -nfs #{shared_path}/#{link} #{release_path}/#{link}" }
    end
  end
end

before "deploy:setup" do
  assets.symlinks.setup
end

before "deploy:create_symlink" do
  assets.symlinks.update
end

desc "Echo environment vars"
namespace :env do
  task :echo do
    run "printenv"
  end
end

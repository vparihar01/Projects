load 'config/_shared_deploy'

# set :repository, "file:///mnt/developer/mysportsbeat.git"
# set :local_repository, "ssh://developer@dev.sportsbeat.com/~/mysportsbeat.git"
set :deploy_to, '/mnt/sportsbeat/dev.sportsbeat.com'
set :deploy_via, :remote_cache
set :user, 'sportsbeat'
set :rails_env, 'dreamhost'
set :branch, "videoupload"

server "dev.sportsbeat.com", :app, :web, :db, :primary => true

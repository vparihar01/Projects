##
# Backup
# Generated Template
#
# For more information:
#
# View the Git repository at https://github.com/meskyanichi/backup
# View the Wiki/Documentation at https://github.com/meskyanichi/backup/wiki
# View the issue log at https://github.com/meskyanichi/backup/issues
#
# When you're finished configuring this configuration file,
# you can run it from the command line by issuing the following command:
#
# $ backup -t my_backup [-c <path_to_configuration_file>]

require 'yaml'
require File.expand_path('../lib/coverpage/feedback',  __FILE__)

rails = Coverpage::RailsEnvironment.new(Coverpage::RailsEnvironment.default.root)
BACKUP = YAML.load(File.read(File.join(File.expand_path('../config/backup.yml', __FILE__))))
CONFIG = YAML.load(File.read(File.join(File.expand_path('../config/config.yml', __FILE__))))[rails.env]
DATABASE = YAML.load(File.read(File.join(File.expand_path('../config/database.yml', __FILE__))))[rails.env]

Backup::Model.new(DATABASE['database'].to_sym, CONFIG['app_name']) do

  database MySQL do |db|
    db.name               = DATABASE['database']
    db.username           = DATABASE['username']
    db.password           = DATABASE['password']
    db.host               = DATABASE['host']
    db.port               = 3306
    # db.socket             = "/tmp/mysql.sock"
    # db.skip_tables        = ['skip', 'these', 'tables']
    # db.only_tables        = ['only', 'these' 'tables']
    # db.additional_options = ['--quick', '--single-transaction']
  end

  store_with SFTP do |server|
    server.username = BACKUP['username']
    server.password = BACKUP['password']
    server.ip       = BACKUP['ip']
    server.port     = BACKUP['port']
    server.path     = BACKUP['path']
    server.keep     = BACKUP['keep']
  end

  compress_with Gzip do |compression|
    compression.best = true
    compression.fast = false
  end

end

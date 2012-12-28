desc "Drop then recreate the dev database, migrate up, and load fixtures" 
task :remigrate => :environment do
  return unless Rails.env == 'development'
  ActiveRecord::Base.connection.recreate_database ActiveRecord::Base.connection.current_database
  ActiveRecord::Base.connection.reconnect!
  Rake::Task['db:migrate'].invoke
  Rake::Task['db:fixtures:load'].invoke
  Rake::Task['import_data'].invoke
  Rake::Task['create_admin'].invoke
end
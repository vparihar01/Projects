require 'yaml'

SCHEDULE = YAML.load(File.read(File.join(File.expand_path('../config/schedule.yml', __FILE__))))

if SCHEDULE['email_nightly'] == true
  every 1.day, :at => '00:05am' do
    rake "email:nightly_files"
  end
end

if SCHEDULE['consolidate_directories'] == true
  every 1.day, :at => '2:05am' do
    SCHEDULE['sub_directories'].each do |web_user|
      # move files to aggregate directory
      %w(covers spreads ebooks).each do |type|
        command "cd #{SCHEDULE['source_directory']} && find #{web_user} -path *#{type}* -type f -mtime -1 -name 978*.pdf -exec mv -v {} #{File.join(SCHEDULE['target_directory'], type)}/ \\;"
      end
    end
  end
end

if SCHEDULE['scan_directories'] == true
  every 1.day, :at => '2:00am' do
    command "cd #{SCHEDULE['source_directory']} && find . -type f -mtime -1 ! -path '*/.*' ! -path '*bak/*' ! -path './george*' ! -path './tim*' ! -path './dreamslice*' ! -path './petersonpub*' ! -path './mollyomara*' ! -path './cherrylake/.*' -print 2>/dev/null"
  end
end

if SCHEDULE['clear_sessions'] == true
  every :sunday, :at => '1:05am' do
    rake "db:sessions:clear"
  end
end

if SCHEDULE['clean_tmp'] == true
  every :sunday, :at => '1:00am' do
    rake "utils:clean"
  end
end

if SCHEDULE['backup_mysql_local'] == true
  every 3.days, :at => '1:10am' do
    command SCHEDULE['mysql_local_command']
  end
end

if SCHEDULE['backup_mysql'] == true
  every 1.day, :at => '11:50pm' do
    command SCHEDULE['mysql_command']
  end
end

if SCHEDULE['rotate_logs'] == true
  every 1.day, :at => '03:05am' do
    command SCHEDULE['rotate_logs_command']
  end
end

if SCHEDULE['clear_wait_a_minute_request_logs'] == true
  # Perform on the 2nd day of every month at 3am
  # Cron syntax is: minute hour day_of_month month day_of_week
  every '0 3 2 * *' do
    runner "sql = ActiveRecord::Base.connection(); sql.execute('DELETE from wait_a_minute_request_logs')"
  end
end

if SCHEDULE['implement_price_changes'] == true
  every 1.day, :at => '00:10am' do
    runner "PriceChange.unimplemented.each {|pc| pc.implement!}"
  end
end

if SCHEDULE['distribute_price_changes'] == true
  every 1.day, :at => '00:15am' do
    runner "PriceChange.distribute"
  end
end


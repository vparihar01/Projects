root_dir = File.expand_path(File.dirname(__FILE__))
stderr_path File.join(root_dir, 'log', 'unicorn.log')
stdout_path File.join(root_dir, 'log', 'unicorn.log')

# What ports/sockets to listen on, and what options for them.
listen File.join('/tmp/sportsbeat.sock'), :backlog => 100
#listen '127.0.0.1:8888', :tcp_nodelay => true

# What the timeout for killing busy workers is, in seconds
timeout 60

# Whether the app should be pre-loaded
preload_app true

# How many worker processes
worker_processes 2

if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = File.join(root_dir, 'Gemfile')
end

# What to do before we fork a worker
before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = File.join(root_dir,'tmp','pids','unicorn.pid.oldbin')
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      puts "Shutting down old process"
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

# What to do after we fork a worker
after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end

# Where to drop a pidfile
pid File.join(root_dir, 'tmp','pids','unicorn.pid')

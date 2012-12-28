# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.expand_path('../feedback',  __FILE__)
require 'pathname'

module Coverpage

  class Site
    @@out = Coverpage::Feedback.new
    
    SITES_DIR = "src/sites" # should contain dirs of VALID_THEMES (relative to Rails.root)
    SITES_FILE = "#{SITES_DIR}/index.yml" # should contain configuration to reach remote site (ssh proto will be used)
    DEPLOY_FILE = "deploy.yml" # should contain the capistrano deployment configuration for the site
    FILES = Dir.glob("#{Coverpage::RailsEnvironment.default.root}/config/*.template.yml").reject{|f| /deploy\.template\.yml$/.match(f)}.map{|f| File.basename(f).sub('.template', '')}.freeze

    attr_reader :name, :role_app, :user, :deploy_to

    def initialize(attributes)
      if attributes.is_a?(String)
        @name = attributes
      else
        attributes.each do |k,v|
          instance_variable_set("@#{k}", v)
        end
      end
    end

    def options
      @@options
    end
    
    def self.options=(opts = {})
      @@options = opts
      if opts[:debug]
        @@out.level = 2
      elsif opts[:verbose]
        @@out.level = 1
      else
        @@out.level = 0
      end
    end

    def remote_dir
      "#{deploy_to}/shared/config"
    end

    def check
      @@out.important "Site: '#{name}'"
      @@out.verbose "  Config theme: #{config['theme']}"
      ensure_local_dir
      ok = self.class.check_config_dir(local_dir)
      self.class.print_settings(settings)
      @@out.error("File(s) missing. Try 'stub #{name}' or 'pull #{name}' to fix.") unless ok
      @@out.verbose "\n"
      # Compare current config.yml to template to find missing keys
      self.class.check_config(File.join(local_dir, "config.yml"))
    end
    
    # Retrieve name of currently activated theme. Check config files.
    def self.check_rails_config
      dir = File.join(rails_env.root, "config")
      @@out.verbose "Rails config directory: #{dir}"
      @@out.verbose "  Config theme: #{config['theme']}"
      ok = check_config_dir(dir)
      print_settings(YAML.load(File.read(File.join(rails_env.root, "config", DEPLOY_FILE))))
      @@out.error("File(s) missing. Try 'stub #{name}' or 'pull #{name}' to fix.") unless ok
      @@out.verbose "\n"
      # Compare current config.yml to template to find missing keys
      check_config(File.join(rails_env.root, "config/config.yml"))
    end
    
    def self.check_config(file)
      # Compare current config.yml to template to find missing keys
      original_config = load_config_settings(file)
      template_config = load_config_settings(File.join(rails_env.root, "config", "config.template.yml"))
      missing = template_config.reject {|k, v| original_config.has_key?(k)}
      if missing.any?
        @@out.error "Config file '#{relative_path(file)}' missing keys:"
        template_config.each {|k, v| @@out.important "    #{k}"}
      end
      @@out.verbose "\n"
    end

    def stub
      FILES.each { |file|
        source = File.join(rails_env.root, 'config', file.sub('.yml', '.template.yml'))
        target = File.join(local_dir, file)
        if !File.exist?(target) || options[:force]
          FileUtils.cp(source, target, :noop => options[:debug], :verbose => options[:verbose])
        else
          @@out.important "File '#{file}' already exists. Try '--force' to clobber."
        end
      }
    end
    
    def zip
      FileUtils.cd(File.dirname(local_dir))
      self.class.run_command("zip -r #{name}-$(date +%Y%m%d%H%M%S).zip #{name}")
    end

    def pull
      zip if Dir.glob("#{local_dir}/*.yml").any? && options[:force]
      FILES.each do |file|
        if !File.exist?(File.join(local_dir, file)) || options[:force]
          self.class.run_command("scp #{user}@#{role_app}:#{remote_dir}/#{file} #{local_dir}")
        else
          @@out.important "File '#{file}' already exists. Try '--force' to clobber."
        end
      end
    end

    def push
      FILES.each do |file|
        self.class.run_command("scp #{local_dir}/#{file} #{user}@#{role_app}:#{remote_dir}")
      end
    end

    def rsync
      # This is a one-direction sync, pushing files to remote, updating/deleting when necessary
      # It does NOT affect local files
      files = Dir.glob("#{local_dir}/*.yml")
      unless files.any?
        @@out.error "No local files found -- Rsync not allowed. To delete all config files from server, login to server directly."
        exit 1
      end
      unless files.size == FILES.size || options[:force]
        @@out.error "Expected #{FILES.size} files, found #{files.size}. Try '--force' if you're certain."
        exit 1
      end
      flags = []
      if options[:debug]
        flags << "--dry-run"
        # Turn debug off so that dry-run can perform
        options[:debug] = false
      end
      flags << "--delete" if options[:delete]
      cmd = "rsync -avz #{flags.join(' ')} --exclude '.DS_Store' --exclude 'Icon' '#{local_dir}/.' '#{user}@#{role_app}:#{remote_dir}/.' -e /usr/bin/ssh"
      if options[:force]
        @@out.important "Preparing forced rsync...\n\n"
        @@out.important " #{cmd}\n\n"
        sleep 3
        @@out.important "  after a brief intermission...\n\n"
        sleep 3
        @@out.important "      ...(music)...\n\n"
        sleep 5
      end
      self.class.run_command(cmd)
    end
    
    def attributes
      atts = {}
      instance_variables.each do |var|
        # Omit the 'name' attribute from the deploy.yml file
        key = var.sub('@', '')
        atts[key] = eval(var) unless key == 'name'
      end
      atts
    end
    
    # Check if there's a symlink. Analyze its destination. 
    # If it contains the site 'name' then consider the site enabled.
    def enabled?
      deploy_config = File.join(rails_env.root, 'config', DEPLOY_FILE)
      if File.symlink?(deploy_config)
        begin
          basename = File.basename(Pathname.new(deploy_config).realpath)
        rescue
          @@out.error "Orphaned deploy symlink found."
          @@out.important "  Run 'disable' command."
          @@out.important "Aborting..."
          exit
        end
        # the following regex must match the filename created by the 'enable' method (see below)
        /^#{name}-/.match(basename) ? true : false
      else
        false
      end
    end
    
    # Check if there's a symlink. Analyze its destination. 
    # If it contains the site 'name' then consider that the enabled site.
    def self.enabled
      deploy_config = File.join(rails_env.root, 'config', DEPLOY_FILE)
      if File.symlink?(deploy_config)
        begin
          basename = File.basename(Pathname.new(deploy_config).realpath)
        rescue
          @@out.error "Orphaned deploy symlink found."
          @@out.important "  Run 'disable' command."
          @@out.important "Aborting..."
          exit
        end
        # the following regex must match the filename created by the 'enable' method (see below)
        if m = /^(.+)-(.+)-(.+)\.yml/.match(basename)
          return m[1]
        else
          @@out.error "Deploy symlink target not named properly '#{basename}'."
          @@out.important "  Try '--force' to override."
          exit
        end
      else
        @@out.error "Found 'config/deploy.yml' file not symlink."
        @@out.important "  Try '--force' to override."
        exit
      end
    end

    # symlinks the site's deployment parameters to the coverpage capistrano recipe's config
    # so that Capistrano operates on the selected site
    def enable
      deploy_config = File.join(rails_env.root, 'config', DEPLOY_FILE)
      deploy_session = File.join(rails_env.root, 'tmp', "#{name}-#{Time.now.strftime("%Y%m%d%H%M%S")}-#{DEPLOY_FILE}")
      if enabled? && !options[:force]
        @@out.verbose "Site '#{name}' is already enabled for deployment."
        @@out.verbose "  Refer to '#{self.class.relative_path(Pathname.new(deploy_config).realpath)}'."
        @@out.verbose "  Try '--force' to clobber existing deployment file."
        return true
      end
      FileUtils.rm_f(deploy_config) if File.exist?(deploy_config) && options[:force]
      if !File.exist?(deploy_config)
        # dump parameters to the file named deploy_session
        output = File.new(deploy_session, 'w')
        output.puts YAML.dump(attributes)
        output.close

        FileUtils.ln_s(deploy_session, deploy_config)
        self.class.run_command("#{File.join(rails_env.root, "script/theme")} enable #{config['theme']}")
        install_config
        @@out.verbose "Site '#{name}' is enabled for deployment."
        @@out.verbose "To disable, run 'script/site disable'."
      else
        if File.symlink?(deploy_config)
          @@out.error "Pre-existing deployment found."
          @@out.important "  Refer to '#{self.class.relative_path(Pathname.new(deploy_config).realpath)}'."
          @@out.important "  Try '--force' or 'script/site disable'."
        else
          @@out.error "Found 'config/deploy.yml' file not symlink."
          @@out.important "  Try '--force' to override."
        end
      end
    end
    
    # Copy site directory config files into development (rails main config dir)
    def install_config
      # This operation is for development purposes only
      return false if rails_env.env == "production"
      
      @@out.verbose "Copying config files to local Rails app config directory..."
      # Move config files into place
      FILES.each do |file|
        # scribd_fu is an exception since it doesn't allow values based on environment (eg, dev vs. test)
        next if file == "scribd_fu.yml"
        source = File.join(local_dir, file)
        target = File.join(rails_env.root, "config")
        FileUtils.cp(source, target, :noop => options[:debug], :verbose => options[:verbose])
      end
      # Restart web server if using passenger
      self.class.restart
    end
    
    # Run diff between installed config files and local original.
    def diff
      target = File.join(rails_env.root, SITES_DIR, name)
      source = File.join(rails_env.root, "config")
      cmd = "diff -u -x #{self.class.exclude_files.join(' -x ')} #{target} #{source}"
      self.class.run_command_without_check(cmd)
    end
    
    def self.exclude_files
      source = File.join(rails_env.root, "config")
      all_config_files = Dir.glob("#{source}/*")
      exclude = all_config_files.map{|x| x.sub("#{source}/", '')}.delete_if {|x| FILES.include?(x)}
      exclude + %w(.DS_Store environments initializers)
    end
    
    # Run diff and patch to create and apply patch for specified file. 
    # Comparing installed config files to local original. 
    # Applying to local original. Use 'reverse' option to apply to installed file.
    def patch
      if options[:reverse]
        source = File.join(rails_env.root, SITES_DIR, name)
        target = File.join(rails_env.root, "config")
      else
        target = File.join(rails_env.root, SITES_DIR, name)
        source = File.join(rails_env.root, "config")
      end
      FileUtils.cd(target, :verbose => options[:verbose])
      if File.directory?(source)
        tmp = File.join(rails_env.root, "tmp/patch.diff")
        self.class.run_command_without_check("diff -u -x #{self.class.exclude_files.join(' -x ')} . #{source} > #{tmp}")
        self.class.run_command_without_check("patch -p0 < #{tmp}")
      else
        @@out.error "Source directory not found '#{source}'"
        @@out.important "Aborting..."
        exit 1
      end
    end

    # removes the config/deploy.yml (that should be a symlink to a site)
    # so that Capistrano gets in an unconfigured state
    # it is a class method as it cleans up any deployment config...
    def self.disable
      deploy_config = File.join(rails_env.root, 'config', DEPLOY_FILE)
      run_command("#{File.join(rails_env.root, "script/theme")} disable")
      if File.symlink?(deploy_config)
        @@out.verbose "Removing 'config/deploy.yml' symlink and destination..."
        # If symlink orphaned, catch error but do nothing
        FileUtils.rm_f(Pathname.new(deploy_config).realpath.to_s, :noop => @@options[:debug], :verbose => @@options[:verbose]) rescue nil
        FileUtils.rm_f(deploy_config, :noop => @@options[:debug], :verbose => @@options[:verbose])
        @@out.verbose "Capistrano deployment is disabled."
      elsif File.exist?(deploy_config)
        @@out.error "Improper deployment configuration."
        @@out.important "  Remove 'config/deploy.yml' manually."
        @@out.important "Aborting..."
        exit 1
      else
        @@out.verbose "Capistrano deployment is already disabled."
      end
    end
    
    def added?(name)
      self.class.settings.has_key?(name)
    end

    def add
      remove if added?(name) && options[:force]
      @@out.verbose "Adding site '#{name}'..."
      unless added?(name)
        ensure_local_dir
        stub # stubs site directory with template files
        stub_data = YAML.load(File.read(File.join(rails_env.root, "config", DEPLOY_FILE.sub('.yml', '.template.yml'))))
        target = File.join(rails_env.root, SITES_FILE)
        if File.exist?(target)
          @@out.verbose "Updating '#{SITES_FILE}'..."
          data = YAML.load(File.read(target))
          data[name] = stub_data
          unless options[:debug]
            File.open(target, 'w') do |out|
              out.write YAML.dump(data)
            end
          end
        else
          @@out.verbose "Creating '#{SITES_FILE}'..."
          data[name] = stub_data
          unless options[:debug]
            File.new(target, 'w') do |out|
              out.write YAML.dump(data)
            end
          end
        end
      else
        @@out.error "Site '#{name}' already found in '#{SITES_FILE}'."
        @@out.important "  Try '--force' option to reinstall."
      end
    end

    def remove
      @@out.verbose "Removing directory '#{self.class.relative_path(local_dir)}'..."
      if File.exist?(local_dir)
        FileUtils.rm_r(local_dir, :noop => options[:debug], :verbose => options[:verbose])
      else
        @@out.verbose "  Directory not found '#{self.class.relative_path(local_dir)}'..."
      end
      @@out.verbose "Updating '#{SITES_FILE}'..."
      target = File.join(rails_env.root, SITES_FILE)
      data = YAML.load(File.read(target))
      data.delete(name)
      unless options[:debug]
        File.open(target, 'w') do |out|
          out.write YAML.dump(data)
        end
      end
    end
    
    def clean
      # Remove files from site directory that aren't listed in FILES (ie, that don't have templates)
      @@out.verbose "Removing unnecessary files from '#{self.class.relative_path(local_dir)}'..."
      Dir.glob("#{local_dir}/*").each do |file|
        basename = File.basename(file)
        unless FILES.include?(basename)
          FileUtils.rm_r(file, :noop => options[:debug], :verbose => options[:verbose])
        end
      end
    end
    
    def self.clean
      dir = File.join(rails_env.root, SITES_DIR)
      @@out.important "Remove zips from '#{SITES_DIR}'..."
      Dir.glob("#{dir}/*.zip").each do |file|
        # FileUtils.rm(file, :noop => options[:debug], :verbose => options[:verbose])
        cmd = "rm -i #{file}"
        @@out.debug "#{cmd}"
        system(cmd) unless @@options[:debug]
      end
    end

    # Read SITES_FILE. Return Site object for each site in file
    def self.all
      file = File.join(Coverpage::RailsEnvironment.default.root, SITES_FILE)
      if File.exist?(file)
        sites = YAML.load(File.read(file))
        sites.collect { |name, attributes| new(attributes.merge('name' => name)) }.sort
      else
        @@out.error "Improper setup. Install '#{SITES_FILE}'."
        exit 1
      end
    end

    def self.find(name)
      if site = all.find {|s| s.name == name }
        site
      else
        @@out.error("Site by name '#{name}' not found")
        exit 1
      end
    end

    def self.check
      all.each do |site|
        site.check
      end
      check_rails_config
    end
    
    def self.info
      @@out.important "Rails root: #{rails_env.root}"
      @@out.important "Rails env: #{rails_env.env}"
      check_rails_config
      @@out.important "Registered sites:"
      Coverpage::Site.all.each { |site| @@out.important "  #{site.name} #{site.enabled? ? '(enabled)' : ''}" }
    end
    
    protected
    
      def <=>(site)
        name <=> site.name
      end

    private

      def self.rails_env
        @@rails_env ||= Coverpage::RailsEnvironment.default
      end

      def rails_env
        @@rails_env ||= Coverpage::RailsEnvironment.default
      end

      def self.run_command_without_check(cmd)
        run_command(cmd, false)
      end
      
      def self.run_command(cmd, check = true)
        @@out.verbose "#{cmd}"
        unless @@options[:debug]
          # if the system command fails and we are supposed to check failure
          if ! system(cmd) && check
            @@out.error "Failed to execute system command '#{cmd}'"
            exit 1
          end
        end
      end

      def local_dir
        File.join(rails_env.root, SITES_DIR, name)
      end
      
      def self.relative_path(dir)
        dir.sub("#{rails_env.root}/", '')
      end
      
      def settings
        @settings ||= self.class.settings[name]
      end
      
      def self.settings
        @@settings ||= YAML.load(File.read(File.join(rails_env.root, SITES_FILE)))
      end
      
      def self.print_settings(data)
        @@out.verbose "  Deploy settings:"
        print_data(data)
      end
      
      def self.load_config_settings(file)
        settings = YAML.load(File.read(file))
        settings['development']
      end
      
      def self.print_data(data)
        data.each do |k,v|
          @@out.verbose "    #{sprintf('%-15s', k)} = #{v}"
        end
      end
      
      def ensure_local_dir
        FileUtils.mkdir(local_dir, :noop => options[:debug], :verbose => options[:verbose]) unless File.directory?(local_dir)
      end
      
      # Restart Application. Options: debug, verbose.
      def self.restart
        FileUtils.touch(File.join(rails_env.root, "tmp/restart.txt"), :noop => @@options[:debug], :verbose => @@options[:verbose])
      end
      
      def self.check_config_dir(dir)
        check_dir(dir)
        results = []
        FILES.each do |file|
          results << check_file(File.join(dir, file))
        end
        !results.include?(false)
      end

      def self.check_dir(dir)
        @@out.verbose "  Checking dir '#{relative_path(dir)}'... ", :print => true
        if File.directory?(dir)
          @@out.verbose "Exists"
          true
        else
          @@out.important "Not found!"
          @@out.important "    Full path = #{dir}"
          false
        end
      end
      
      def self.check_file(path)
        @@out.verbose "    Checking file '#{relative_path(path)}'... ", :print => true
        if File.exist?(path)
          @@out.verbose "Exists"
          true
        else
          @@out.important "Not found!"
          @@out.important "      Full path = #{path}"
          false
        end
      end
      
      def config
        @config ||= self.class.load_config(local_dir)
      end
      
      def self.config
        @@config ||= load_config(File.join(rails_env.root, "config"))
      end
      
      def self.load_config(dir)
        YAML.load(File.read("#{dir}/config.yml"))[rails_env.env]
      end
  end
end

class Uploader
  require 'rubygems'
  require 'uri'
  require 'net/ftp'
  require 'net/sftp'

  attr_reader :error, :uri, :host, :path, :user
  
  def initialize(url, options = {})
    unless match = url.match(%r|(\w+)://|)
      @scheme = 'ftp'
      host, path = url.split %r|:/+|o
      url = "ftp://#{ host }/#{ path }"
    else
      @scheme = match[1]
    end
    raise ArgumentError, "Error: Unsupported scheme (#{@scheme})" unless %w(ftp sftp).include?(@scheme)
    # If we're not in production mode, upload to webmaster ftp, in a
    # directory associated with the original url
    unless Rails.env.production?
      key = "webmaster_#{@scheme}".to_sym
      webmaster = CONFIG[key]
      raise ArgumentError, "Error: Undefined CONFIG key '#{key.to_s}'" if webmaster.nil? || webmaster.empty?
      uri = URI::parse(url)
      url = File.join(webmaster, File.join(uri.host, uri.path).gsub("/", "-")).gsub(/-$/, '')
    end
    @error = false
    @debug = (options[:debug] == true)
    @verbose = (@debug || options[:verbose] == true)
    # TODO: add passive option to recipient model
    @passive = (options[:passive] != false)
    @uri = URI::parse(url)
    @host = @uri.host
    if @scheme == 'sftp'
      @path = @uri.path.gsub(/^\//, '')
    else
      @path = @uri.path
    end
    if @uri.userinfo.nil?
      @user = "anonymous"
      @password = nil
    else
      @user, @password = @uri.userinfo.split(':')
    end
  end

  def put(source, ext = nil)
    self.send("#{@scheme}_put", source, ext)
  end

  protected

  def sftp_put(source, ext = nil)
    raise ArgumentError, "Error: Source not found (#{source})" unless Coverpage::Utils.test_file(source)
    if @verbose
      host = @host; path = @path; user = @user; password = @password
      FEEDBACK.print_variable(%w(host path user password source), binding)
    end
    begin
      Net::SFTP.start(@host, @user, :password => @password) do |ftp|
        FEEDBACK.verbose("START: #{Time.now}") if @verbose

        # ensure path target directory exists
        if !@path.nil? && !@path.empty?
          tmp = ""
          @path.split("/").each do |dir|
            next if dir.blank?
            tmp = (tmp.blank? ? dir : "#{tmp}/#{dir}")
            FEEDBACK.verbose("Creating target directory '#{tmp}'...") if @verbose
            begin
              ftp.mkdir!(tmp)
            rescue Exception => e
              FEEDBACK.error "Failed to create target directory '#{tmp}' -- #{e}"
            end
          end
        end
        begin
          unless @path.nil? || @path.empty?
            handle = ftp.opendir!(@path)
          end
        rescue Exception => e
          FEEDBACK.error "Failed to open target directory '#{@path}' -- #{e}"
          @error = true
          return false
        end

        result = {}
        if File.directory?(source)
          # upload files in directory to remote host
          Dir.glob(File.join(source, ext.blank? ? "*" : "*.#{ext.gsub('.','')}")) do |file|
            result[file] = sftp_put_file(ftp, file)
          end
        else
          result[source] = sftp_put_file(ftp, source)
        end

        FEEDBACK.verbose("DONE: #{Time.now}") if @verbose
        FEEDBACK.print_variable('result', binding) if @verbose
        return !result.values.include?(false)
      end
    rescue Exception => e
      FEEDBACK.error "Login failed -- #{e}"
      @error = true
      return false
    end
  end

  def sftp_put_file(ftp, file)
    base = File.basename(file)
    target = (@path.blank? ? base : "#{@path}/#{base}")
    FEEDBACK.verbose("  Transferring '#{base}'...") if @verbose
    begin
      ftp.upload!(file.to_s, target) unless @debug
      true
    rescue Exception => e
      FEEDBACK.error "Upload failed -- #{e}"
      return false
    end
  end

  def ftp_put(source, ext = nil)
    raise ArgumentError, "Error: Source not found (#{source})" unless Coverpage::Utils.test_file(source)
    if @verbose
      host = @host; path = @path; user = @user; password = @password
      Coverpage::Utils.print_variable(%w(host path user password source), binding)
    end
    begin
      Net::FTP.open(@host, @user, @password) do |ftp|
        FEEDBACK.verbose("START: #{Time.now}") if @verbose
        if @passive
          FEEDBACK.verbose("Sending passive mode command 'PASV'...") if @verbose
          ftp.passive = true
        end

        # ensure path target directory exists
        if !@path.nil? && !@path.empty?
          tmp = ""
          @path.split("/").each do |dir|
            next if dir.blank?
            tmp = (tmp.blank? ? dir : "#{tmp}/#{dir}")
            FEEDBACK.verbose("Creating target directory '#{tmp}'...") if @verbose
            begin
              ftp.mkdir(tmp)
            rescue Exception => e
              FEEDBACK.error "Failed to create target directory '#{tmp}' -- #{e}"
            end
          end
        end
        begin
          ftp.chdir(@path) if !@path.nil? && !@path.empty?
        rescue Exception => e
          FEEDBACK.error "Failed to open target directory '#{@path}' -- #{e}"
          @error = true
          return false
        end

        result = {}
        if File.directory?(source)
          # upload files in directory to remote host
          Dir.glob(File.join(source, ext.blank? ? "*" : "*.#{ext.gsub('.','')}")) do |file|
            result[file] = ftp_put_file(ftp, file)
          end
        else
          result[source] = ftp_put_file(ftp, source)
        end

        FEEDBACK.verbose("DONE: #{Time.now}") if @verbose
        FEEDBACK.print_variable('result', binding) if @verbose
        return !result.values.include?(false)
      end
    rescue Exception => e
      FEEDBACK.error "Login failed -- #{e}"
      @error = true
      return false
    end
  end

  def ftp_put_file(ftp, file)
    base = File.basename(file)
    FEEDBACK.verbose("  Transferring '#{base}'...") if @verbose
    begin
      ftp.put(file) unless @debug
      true
    rescue Exception => e
      FEEDBACK.error "Upload failed -- #{e}"
      return false
    end
  end

end

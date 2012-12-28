namespace :version do

  class AppVersion
    attr_accessor :major, :minor, :patch
    VERSION_FILE = Rails.root.join("VERSION.yml")

    def initialize
      return unless File.exist?( VERSION_FILE )
      version = YAML.load_file( VERSION_FILE )
      ( self.major, self.minor, self.patch ) = version[:major], version[:minor], version[:patch]
    end

    def to_s
      "#{major}.#{minor}.#{patch}"
    end

    def new( major = 0, minor = 1, patch = 0)
      yield
    end

    def bump( to = nil )
      if to.nil? or to.blank?
        self.patch += 1
      else
        self.from_s(to)
      end
      self
    end

    def save
      File.open( VERSION_FILE, 'w' ) do |out|
        out << "--- \n:major: #{self.major}\n:minor: #{self.minor}\n:patch: #{self.patch}\n\n"
      end
    end

    protected

      def from_s(version_string)
        tmajor, tminor, tpatch = version_string.split('.').collect { |i| i.to_i }
        tpatch ||= 0
        (self.major, self.minor, self.patch) = tmajor, tminor, tpatch
      end
  end

  # end of class

  desc "Print version"
  task :print => :environment do
    v = AppVersion.new
    puts v
  end

  desc "Bump version. Options: to."
  task :bump => :environment do
    v = AppVersion.new
    if ENV['to'].nil? or ENV['to'].blank?
      puts "bumping to next patchlevel."
    elsif ENV['to'].match(/^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,3}$/)
      puts "bumping to #{ENV['to']}"
    elsif ENV['to'].match(/^[0-9]{1,2}\.[0-9]{1,2}$/)
      puts "bumping to #{ENV['to']}"
    else
      raise "'#{ENV['to']}' does not seem to be a valid version."
    end
    v.bump( ENV['to'] )
    v.save
    puts v
  end

end



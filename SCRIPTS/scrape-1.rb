require 'rubygems'
require 'date'
require 'ftools'
require 'httpclient'
require 'nokogiri'

ENV['PATH'] += '/opt/local/bin'

require 'quick_magick'


# Put shared classes in a module to avoid naming conflicts
module DFG

# A simple wrapper to encapsulate logging.
# For now it just writes to stdout/stderr, but the implementation can
# easily be improved/replaced as needed (e.g. send an email on error).
class Log
  # Logging level
  DISABLED = 0
  CRITICAL = 1
  ERROR = 2
  WARNING = 3
  INFO = 4
  NOTICE = 5
  DEBUG = 6
  TRACE = 7

  # Default logging level
  @@level = NOTICE

  # Use to get/set logging level
  def self.level() @@level; end
  def self.level=(l) @@level = l; end

  # Log a trace message
  def self.t(message)
    return if @@level < TRACE
    $stdout.puts("TRACE: " + message.to_s)
  end

  # Log a debug message
  def self.d(message)
    return if @@level < DEBUG
    $stdout.puts("DEBUG: " + message.to_s)
  end

  # Log a notice message
  def self.n(message)
    return if @@level < NOTICE
    $stdout.puts("NOTICE: " + message.to_s)
  end

  # Log an info message
  def self.i(message)
    return if @@level < INFO
    $stdout.puts("INFO: " + message.to_s)
  end

  # Log a warning
  def self.w(warning)
    return if @@level < WARNING
    $stderr.puts("WARNING: " + warning.to_s)
  end
 
  # Log an error
  def self.e(error)
    return if @@level < ERROR
    case error
      when Exception
        $stderr.puts("ERROR: " + error.to_s + "\n  " + error.backtrace.join("\n  "))
      else
        $stderr.puts("ERROR: " + error.to_s)
    end
  end

  # Log a critical error
  def self.c(error)
    return if @@level < CRITICAL
    case error
      when Exception
        $stderr.puts("CRIT: " + error.to_s + "\n  " + error.backtrace.join("\n  "))
      else
        $stderr.puts("CRIT: " + error.to_s)
    end
  end
end

# A simple wrapper class to help build the arrest hash
# It will allow us to perform common formatting/validation in one place
class Arrest < Hash
  # Constructor
  def initialize()
    self[:charges] = []
  end

  # Simple getters and setters for the keys used by the shared classes below
  # (It is perfectly acceptable to add other keys to the hash while building the Arrest object)
  def date() self[:date]; end
  def date=(v)
    self[:date] = case v
      when DateTime, Date, Time then v.strftime("%Y-%m-%d")
      else Date.parse(v.to_s).strftime("%Y-%m-%d")
    end
      Log.d("Setting date: #{self[:date]}")
  end
  def first() self[:first]; end
  def first=(v) self[:first] = v.to_s.strip; end
  def last() self[:last]; end
  def last=(v) self[:last] = v.to_s.strip; end
  def image1() self[:image1]; end
  def image1=(v) self[:image1] = v.to_s.strip; end
  def image2() self[:image2]; end
  def image2=(v) self[:image2] = v.to_s.strip; end
  def charges() self[:charges]; end
  def charges=(v) self[:charges] = v; end

  # Automatically splits "last, first" into last and first names
  def name=(name)
    arr = name.split(',')
    self.last, self.first = arr[0], arr[1]
    Log.d("Setting name: #{self.last}, #{self.first}")
  end

  # Call to add a charge to the arrest
  def add_charge(desc, bond)
    self[:charges] << {
      :desc => desc.to_s.strip,
      :bond => bond.to_s.gsub('$', '').strip.to_i
   	}
    Log.d("Adding charge: #{self[:charges].last[:desc]}, #{self[:charges].last[:bond]}")
  end
end

# Encapsulates a scraping session.
# Includes an HTTP client session to manage cookies and HTTP headers, to
# standardize image downloads, and to insert Arrest objects into the database.
class Scrape
  # Constants
  DB_SERVER = "localhost"
  DB_LOGIN = ""
  DB_PASSWORD = ""
  DB_NAME = ""
  #IMAGE_PATH = "/home/dreamforgegames.com/web/elements/justice/images/"
  IMAGE_PATH = "./images/"
  IMAGE_MAX_WIDTH = 120
  IMAGE_MAX_HEIGHT = 150
  DEFAULT_IMAGE = "/justice/images/default.jpg"
  DEFAULT_HEADERS = {
    'User-Agent' => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0; chromeframe/13.0.782.215)',
  }

  # Getter methods for members
  # AMF - added responseHeaders to store response headers after a post
  attr_reader :state, :county, :city, :client, :conn, :headers, :count, :responseHeaders

  # Constructor (creates an HTTPClient object to use for all GET/POST requests)
  # AMF - added image parameter in case images are located somewhere other than base
  def initialize(state, county, city, base, image = nil)
    @state, @county, @city, @base, @image = state, county, city, base, image || base
    @client = HTTPClient.new()
    @arrests = {}
    if ARGV[0] == "test"
      Log.level = Log::DEBUG
      Log.i("Starting test for: #{state}, #{county}, #{city}")
    else
      Log.i("Starting scrape for: #{state}, #{county}, #{city}")
      require 'mysql'
      @conn = Mysql.real_connect(DB_SERVER, DB_LOGIN, DB_PASSWORD, DB_NAME)
      @conn.autocommit(false)
      @insert_arrest = @conn.prepare(format("INSERT INTO arrests (state, county, city, arrest_date, last_name, first_name, image1, image2) VALUES ('%s', '%s', '%s', ?, ?, ?, ?, ?)",  @conn.escape_string(@state), @conn.escape_string(@county), @conn.escape_string(@city)))
      @insert_charge = @conn.prepare("INSERT INTO charges (arrest_id, charge_num, description, bond_amount) VALUES (?, ?, ?, ?)")
      @results = @conn.query(format("SELECT arrest_date, last_name, first_name FROM arrests WHERE state = '%s' AND county = '%s' AND city = '%s'",  @conn.escape_string(@state), @conn.escape_string(@county), @conn.escape_string(@city)))
      @results.each {|r|
        key = arrest_key(r[0], r[1], r[2])
        @arrests[key] = true
        Log.t("Loading: #{key}")
      }
    end
    @headers = DEFAULT_HEADERS.clone
    @count = 0
  end

  # Ruby has no destructors, so call this when finished to commit changes
  # to the database. If you don't call it, changes will be rolled back.
  def commit()
    @conn.commit if @conn
    Log.i("#{@count} new bookings added")
  end

  # This key is used to generate a hash code, so it must ALWAYS
  # look the same for the same arrest in the current state/county/city.
  # The date format should be YYYY-MM-DD (the format returned by MySQL).
  def arrest_key(date, last, first)
    "#{date}-#{last}-#{first}".downcase
  end

  # Helper to return a Nokogiri doc using our HTTPClient object
  # (which manages HTTP cookies and headers).
  def get(url, query = nil, headers = nil)
    headers = headers ? @headers.merge(headers) : @headers
    #Log.t("GET: #{url}\n#{query.inspect}\n#{headers.inspect}")
    content = @client.get_content(URI.join(@base, url), query, headers) rescue ''
    Nokogiri::HTML(content)
  end

  # Helper to post a form and return a Nokogiri doc using our HTTPClient object
  # (which manages HTTP cookies and headers).
  def post(url, query = nil, headers = nil)
    headers = headers ? @headers.merge(headers) : @headers
    #Log.t("POST: #{url}\n#{query.inspect}\n#{headers.inspect}")
    res = @client.post(URI.join(@base, url), query, headers) rescue nil
    if res != nil
      @responseHeaders = res.header
      Nokogiri::HTML(res.body)
    else
      Nokogiri::HTML('')
    end
  end

  # Call to add a new arrest to the database
  def add(arrest)
    # Skip this arrest if we've already tried to download it
    key = arrest_key(arrest.date, arrest.last, arrest.first)
    if @arrests.has_key?(key)
      Log.d("Skipping arrest: #{key}")
      Log.d("---------------------")
      return nil
    end
		
    # Download the images
    # AMF - changed this to use the new image property instead of base
    image1 = download_image(URI.join(@image, arrest.image1), 1, key) rescue nil
    image2 = download_image(URI.join(@image, arrest.image2 || arrest.image1), 2, key) rescue nil
    image1 ||= DFG::Scrape::DEFAULT_IMAGE
    image2 ||= image1

    # Add this arrest to the hash (so we don't try to download it again)
    Log.d("Adding arrest: #{key}")
    @count += 1
    @arrests[key] = true

    id = 0
    if @conn # Don't execute the queries in test mode
      @insert_arrest.execute(arrest.date, arrest.last, arrest.first, image1, image2)
      id = @conn.insert_id
      arrest.charges.each_index {|i|
        charge = arrest.charges[i]
        @insert_charge.execute(id, i, charge[:desc], charge[:bond]) rescue next
      }
    end
    Log.d("---------------------")
    return id
  rescue Exception
    Log.e($!)
    return nil
  end

  # Method to process an image using QuickMagick
  # NOTE: Override for sites that need special image handling
  def process_image(src, dest, maxw, maxh)
    i = QuickMagick::Image.read(src).first
    # AMF - added quality setting to limit size of images (some sites had high quality jpeg, so files sizes were still big)
    i.quality = 75
    w, h = i.width, i.height
    extra = (w - h/(maxh.to_f/maxw.to_f)).to_i
    if extra > 0
      i.shave("#{extra>>1}x0") if i.width > i.height
      w -= extra
    end
    if w > maxw or h > maxh
      i.resize("#{maxw}x#{maxh}")
    end
    i.save(dest)
  end

  # Method to download an image file.
  # NOTE: IN general, you should not call this directly.
  def download_image(url, n, key)
    # Build the relative web path, the full local path, and a temp file path
    web_path = format("%s/%8.8x.jpg", url.host, "#{key}-#{n}".hash & 0xFFFFFFFF)
    full_path = IMAGE_PATH + web_path
    temp_path = File.join(File.dirname(full_path), "temp.img")

    if File.exists?(full_path)
      # If the file exists, don't bother downloading it again
      Log.d("Skipping image: #{key}-#{n}")
    else
      # Else download the image to a temp file
      # AMF - changed logic here to "get" the page first to see if it is valid, and then process it if it is
      Log.d("Downloading image: #{url} - #{key}-#{n}")
      File.makedirs(File.dirname(temp_path))
            
      response = @client.get(URI.join(@base, url), nil, @headers) rescue nil
			
      # AMF - checking response.content.size > 1000 weeds out some missing image links
      # that seem to be undetectable 
      if response != nil
        if response.status != 404 && response.content.size > 1000
          File.open(temp_path, "wb") {|f| f.write(response.content) }

          # Process the image using an overridable method
          process_image(temp_path, full_path, IMAGE_MAX_WIDTH * n, IMAGE_MAX_HEIGHT * n)

          # Delete the temp file
          File.delete(temp_path)
        else
          Log.d("Download failed. Status: #{response.status}, Size: #{response.content.size}")
          Log.d("#{response.content}")
          return nil
        end
      else
        return nil
      end
    end
    return web_path
  rescue Exception
    Log.e($!)
    return nil
  end

end # class Scrape

end # module DFG


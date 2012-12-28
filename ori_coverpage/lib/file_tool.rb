module FileTool
  require 'rubygems'
  require 'fastercsv'
  
  TMP_DIR = "/tmp"
  
  def self.read_csv(file, verbose = nil)
    begin
      FasterCSV.read(file, :headers => true,
        :skip_blanks => true, 
        :header_converters => :symbol)
    rescue Errno::ENOENT
      puts "Error -- file not found: #{file}"
      return Array.new
    end
  end
  
  def self.read_lines(file, verbose = nil)
    # f = File.open(file) or die "Unable to open file..."
    begin
      f = File.open(file)
      a = Array.new
      f.each_line { |line| a << line.strip }
    rescue Errno::ENOENT
      puts "Error -- file not found: #{file}"
      return Array.new
    end
    return a
  end
  
  def self.random_basename(base = "temp", ext = nil)
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    basename = "#{base}-#{timestamp}-#{rand(10000000)}"
    (ext && ext != '') ? "#{basename}.#{ext}" : basename
  end
  
  def self.random_filename(dir = TMP_DIR, base = "temp", ext = nil)
    File.join(dir, random_basename(base, ext))
  end
  
  def self.file_ext(file)
    # Determine file extension, removing initial period
    File.extname(file).gsub(/^\./, '')
  end
  
  def self.remove(*args)
    args.each do |file|
      FileUtils.rm(file) if file && File.exist?(file)
    end
  end
  
end

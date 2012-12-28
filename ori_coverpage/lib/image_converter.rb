module ImageConverter
  IMAGES_DIRECTORY = Rails.root.join('public/images')
  COVERS_DIRECTORY = File.join(IMAGES_DIRECTORY, 'covers')
  SPREADS_DIRECTORY = File.join(IMAGES_DIRECTORY, 'spreads')
  GLIDERS_DIRECTORY = File.join(IMAGES_DIRECTORY, 'gliders')
  CONVERT = CONFIG[:convert]
  IDENTIFY = CONFIG[:identify]
  OPTIONS = {
    :s => "-density 72 -scale #{CONFIG[:website_image_scale_s]*100}% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#ddd' -shadow 100x0+2+2 \\) +swap -background '#fff' -layers merge +repage -compress JPEG -quality 60%",
    :m => "-density 72 -scale #{CONFIG[:website_image_scale_m]*100}% -bordercolor '#ddd' -border 1x1 \\( +clone -background '#ddd' -shadow 100x0+2+2 \\) +swap -background '#fff' -layers merge +repage -compress JPEG -quality 60%",
    :l => "-density 72 -scale #{CONFIG[:website_image_scale_l]*100}% -bordercolor '#ddd' -border 1x1 -background '#fff' -compress JPEG -quality 60%"
  }

  def self.log(msg)
    puts "# #{msg} "
    Rails.logger.debug "# #{msg} " unless Rails.blank?
  end
  
  def self.convert_image_directory(image_directory, force=false)
    log("Converting image directory: #{image_directory}")
    if File.directory?(image_directory)
      %w(covers spreads).each do |type|
        type_directory = File.join(image_directory, type)
        if File.directory?(type_directory)
          image_files = Dir.glob(File.join(type_directory, "*.jpg"))
          image_files.each {|image| convert_image(image, type, force) }
        else
          log("Error: Directory must be named either 'covers' or 'spreads'")
        end
      end
    else
      log("Error: Directory not found (#{image_directory})")
    end
  end

  def self.convert_image(source, type, force=false)
    # generate resized versions of given image
    filename = File.basename(source)
    log("#{filename}...")
    OPTIONS.each do |size, options|
      target = File.join(IMAGES_DIRECTORY, "#{type}/#{size}", filename)
      log("  Resizing '#{type}/#{size}'...")
      convert(source, target, force) do
        "#{CONVERT} #{source} #{OPTIONS[size]} #{target}"
      end
    end
  end
  
  def self.convert(source, target, force=false)
    source = [source] unless source.is_a?(Array)
    source.each do |file|
      unless File.exist?(file)
        log("  ERROR: source not found '#{file}'")
        return false
      end
    end
    if !force && File.exist?(target)
      log("  Skipped -- target exists")
      return false
    end
    command = yield
    if result = system(command)
      target
    else
      log(command)
      false
    end
  end
  
end

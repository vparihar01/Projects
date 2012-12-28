class Pdf
  require 'file_tool'
  
  TMP_DIR = "/tmp"
  SED_FLAG = "-r" # GNU sed must be installed (BSD sed does not work)
  
  attr_reader :error, :path, :pdftk_version
  
  def initialize(path, options = {})
    options = options.symbolize_keys.delete_if{|k, v| v.nil?}
    @error = false
    @path = path
    @attempt = 0
    pdftk_cmd = "#{CONFIG[:pdftk]} --version"
    @pdftk_version = %x[#{pdftk_cmd}].to_s.scan(/pdftk (\d+).(\d+)/).join(".").to_f
    unless File.exist?(path)
      @error = true
      return false
    end
  end
  
  def extract(options = {})
    crop = (options[:crop] && options[:crop] == true)
    page = (options[:page].is_a?(Integer) && options[:page] > 0 ? options[:page] : 1)
    
    # Create target name
    stamp = "-#{sprintf("%02d", page)}"
    basename = File.basename(self.path)
    if m = /(.*?)\.(\w+)$/.match(basename)
      ext = m[2]
      isbn = m[1]
      new_basename = "#{isbn}#{stamp}.#{ext}"
    else
      new_basename = "#{basename}#{stamp}"
    end
    target = File.join(File.dirname(self.path), new_basename)
    
    # Extract
    FEEDBACK.verbose("  Extracting page number #{page}...")
    cmd = "#{CONFIG[:gs]} -sDEVICE=pdfwrite -q -dNOPAUSE -dBATCH -sOutputFile=#{target} -dFirstPage=#{page} -dLastPage=#{page} #{self.path}"
    FEEDBACK.debug(cmd)
    unless system(cmd)
      FEEDBACK.error("Failed to execute system command '#{cmd}'")
      target = nil
    end
    if target && crop
      FEEDBACK.verbose("  Fixing crop...")
      fix(target, target)
    end
    return target
  end
  
  def width(options = {})
    value = get_format_value("%w", options)
    return cast_to_integer_and_confirm(value)
  end
  
  def height(options = {})
    value = get_format_value("%h", options)
    return cast_to_integer_and_confirm(value)
  end
  
  def cover(target, options = {})
    density = (options[:density].is_a?(Integer) && options[:density] >= 72 ? options[:density] : 150)
    page = 1
    crop = Coverpage::Utils.str_to_boolean(options[:crop], :default => true) # cover default is true / spread default is false
    color = Coverpage::Utils.str_to_boolean(options[:color], :default => true)
    # Initial extract
    tmp = extract(:page => page, :crop => crop)
    if FileTool.file_ext(target) == 'pdf'
      # Simply move extract (which is a pdf) to target
      FileUtils.move(tmp, target)
    else
      # Convert extract
      result = convert(tmp, target, :density => density, :color => color)
      FileUtils.rm(tmp)
      unless result || @attempt > 0
        @attempt += 1
        FEEDBACK.important("Attempting to create cover with opposite cropping...")
        cover(target, options.merge(:crop => !crop))
      end
    end
  end
  
  def spread(target, options = {})
    midline = Coverpage::Utils.str_to_boolean(options[:midline], :default => true)
    density = (options[:density].is_a?(Integer) && options[:density] >= 72 ? options[:density] : 150)
    page = (options[:page].is_a?(Integer) && options[:page] >= 1 ? options[:page] : 10)
    crop = Coverpage::Utils.str_to_boolean(options[:crop], :default => false) # cover default is true / spread default is false
    color = Coverpage::Utils.str_to_boolean(options[:color], :default => true)
    
    # Ensure page number is even
    page +=1 unless page % 2 == 0
    
    # Extract pages from pdf
    pdf_lt = extract(:page => page, :crop => crop)
    pdf_rt = extract(:page => (page + 1), :crop => crop)

    # Determine dimensions of spread
    width = width(pdf_lt)
    height = height(pdf_lt)
    density_in = density
    width_page_in = width * density_in / 72
    height_page_in = height * density_in / 72
    width_page_out = width * density / 72
    height_page_out = height * density / 72
    width_spread = width_page_out * 2

    # Combine pdf pages into spread
    if width_spread > 3 * height_page_out
      # This image is probably a spread already (old tcw book, photograph of spread)
      FEEDBACK.warning "Guessing that extract is already spread..."
      convert(pdf_lt, target, :density => density_in, :color => color)
    else
      # TODO: which is better: white or transparent bg? I think white at this time...
      # xc:none (transparent background) is black with jpeg format
      # bg = extension == 'jpg' ? "xc:white" : "xc:none"
      bg = "xc:white"
      msg = ""
      if midline
        msg += "  Creating composite with midline...\n"
        ml = "-fill '#000000' -draw 'fill-opacity 0.2 rectangle #{width_page_out-3},0 #{width_page_out},#{height_page_out}' -fill '#ffffff' -draw 'fill-opacity 0.2 rectangle #{width_page_out},0 #{width_page_out+3},#{height_page_out}' -fill '#333333' -draw 'line #{width_page_out},0 #{width_page_out},#{height_page_out}'"
      else
        msg += "  Creating composite...\n"
        ml = ""
      end
      # Determine format to which we're converting (based on file extension)
      ext = FileTool.file_ext(target) || "unknown format"
      # Test format for compression requirement
      compress = ( /^tif{1,2}$/i.match(ext) ? "-compress LZW" : "" )
      # compress = ( /^jpe?g$/i.match(ext) ? "-compress JPEG -quality 96" : "" )
      # Test colorspace
      # TODO: does this need '-colorspace RGB'
      cmd = "#{CONFIG[:convert]} #{compress} \\( \\( \\( -size #{width_spread}x#{height_page_out} #{bg} \\) \\( -density #{density_in} #{pdf_lt} \\) -geometry +0+0 -composite \\( -density #{density_in} #{pdf_rt} \\) -geometry +#{width_page_out}+0 -composite \\) #{ml} \\) -colorspace RGB #{target}"
      if color
        FEEDBACK.verbose("  Determining colorspace...\n")
        # [0] means to analyze the first page of the pdf, in case of a multipage pdf
        colorspace = `#{CONFIG[:identify]} -verbose '#{self.path}[0]' | #{CONFIG[:awk]} '/Colorspace/ {print $2}'`.strip
        if colorspace == 'CMYK'
          FEEDBACK.verbose("  CMYK detected...\n")
          cmd = "#{CONFIG[:convert]} #{compress} -colorspace CMYK \\( \\( \\( -size #{width_spread}x#{height_page_out} #{bg} \\) \\( -density #{density_in} #{pdf_lt} \\) -geometry +0+0 -composite \\( -density #{density_in} #{pdf_rt} \\) -geometry +#{width_page_out}+0 -composite \\) #{ml} \\) -colorspace RGB #{target}"
        end
      end
      FEEDBACK.verbose(msg)
      FEEDBACK.debug(cmd)
      result = system(cmd)
      unless result || @attempt > 0
        FEEDBACK.error "Failed to run spread system command"
        @attempt += 1
        FEEDBACK.important("Attempting to create cover with opposite cropping...")
        spread(target, options.merge(:crop => !crop))
      end
    end

    # Cleanup
    FileTool.remove(pdf_lt, pdf_rt)
  end
  
  def pages(options = {})
    # File must be an uncompressed PDF
    uncompressed_tmp = uncompress(self.path, options)
    FEEDBACK.verbose("  Retrieving number of pages...")
    page = `#{CONFIG[:pdftk]} #{uncompressed_tmp} dump_data output - | #{CONFIG[:awk]} '/^NumberOfPages/ {print $2}'`.to_i
    unless page.is_a?(Integer) && page > 0
      @error = true
      FEEDBACK.error "Failed to extract number of pages"
      return false
    end
    return page
  end

  def endsheet(target, density = 150)
    bg = "xc:white"
    width = width(self.path)
    height = height(self.path)
    width_out = width * density / 72
    height_out = height * density / 72
    cmd = "#{CONFIG[:convert]} -size #{width_out}x#{height_out} #{bg} -density #{density} -colorspace RGB #{target}"
    ext = FileTool.file_ext(target) || "unknown format"
    FEEDBACK.verbose("  Creating #{ext.upcase} endsheet...")
    FEEDBACK.debug(cmd)
    unless system(cmd)
      FEEDBACK.error "Failed to create endsheet #{self.path}"
      return false
    end
    target
  end
  
  def press_to_back(target, width, height, padding=81, options = {})
    density = (options[:density].is_a?(Integer) && options[:density] >= 72 ? options[:density] : 150)
    color = Coverpage::Utils.str_to_boolean(options[:color], :default => true)

    source_width = width(self.path)
    crop_x = padding
    crop_y = padding
    density_in = density * 2
    width_in = (width * density_in).to_i
    height_in = (height * density_in).to_i
    width_out = (width * density).to_i
    crop_x_in = (crop_x * density_in / 72).to_i
    crop_y_in = (crop_y * density_in / 72).to_i

    crop(target, density_in, width_in, height_in, crop_x_in, crop_y_in, width_out, density)
  end
  
  def press_to_front(target, width, height, padding=81, options = {})
    density = (options[:density].is_a?(Integer) && options[:density] >= 72 ? options[:density] : 150)
    color = Coverpage::Utils.str_to_boolean(options[:color], :default => true)

    source_width = width(self.path)
    crop_x = (source_width - width * 72 - padding).to_i
    crop_y = padding
    density_in = density * 2
    width_in = (width * density_in).to_i
    height_in = (height * density_in).to_i
    width_out = (width * density).to_i
    crop_x_in = (crop_x * density_in / 72).to_i
    crop_y_in = (crop_y * density_in / 72).to_i

    crop(target, density_in, width_in, height_in, crop_x_in, crop_y_in, width_out, density)
  end
  
  def interior(target, options = {})
    fix(self.path, target, options)
  end

  # This method has been replaced. pdftk fails to update metadata. using exiftool instead.
  # def apply_metadata(file, target, options = {})
  #   uncompressed_tmp = uncompress(self.path, options)
  #   compress(uncompressed_tmp, target, options.merge(:meta => file))
  #   # Cleanup
  #   FileTool.remove(uncompressed_tmp)
  #   target
  # end
  
  def apply_metadata(options = {})
    cmd = "#{CONFIG[:exiftool]} -overwrite_original -Title='#{options[:title].gsub("'", "")}' -Author='#{options[:author].gsub("'", "")}' -Subject='' -Keywords='' #{self.path}"
    unless system(cmd)
      FEEDBACK.error "Failed to apply metadata"
      return false
    end
    true
  end
  
  protected
  
  def fix(file, target, options = {})
    uncompressed_tmp = uncompress(file, options)
    fixed_tmp = fix_uncompressed(uncompressed_tmp, options)
    compress(fixed_tmp, target, options)
    # Cleanup
    FileTool.remove(uncompressed_tmp, fixed_tmp)
  end
  
  def uncompress(file, options = {})
    uncompressed_tmp = FileTool.random_filename(TMP_DIR, "temp_uncompressed", "pdf")
    FEEDBACK.verbose("  Uncompressing PDF...")
    unless system("#{CONFIG[:pdftk]} #{file} output #{uncompressed_tmp} uncompress")
      @error = true
      FEEDBACK.error "Failed to uncompress -- Abort"
      return false
    end
    return uncompressed_tmp
  end
  
  def fix_uncompressed(file, options = {})
    # File must be an uncompressed PDF
    coords = trimbox_for_single_page(file)
    fixed_tmp = FileTool.random_filename(TMP_DIR, "temp_uncompressed_fixed", "pdf")
    FEEDBACK.verbose("  Performing search/replace in PDF...")
    # Have encountered issues with pdfs created with pdf_extract.rb
    # cmd = "#{CONFIG[:sed]} #{SED_FLAG} \"/pdftk_PageNum 1$/,/pdftk_PageNum/ s/(Media|Crop|Art|Bleed)Box \\[.*\\]/\\1Box [#{coords}]/\" #{uncompressed_tmp} > #{fixed_tmp}"
    if @pdftk_version >= 1.44
      cmd = "#{CONFIG[:sed]} #{SED_FLAG} \"s/(Media|Crop|Art|Bleed)Box \\[.*\\]/\\1Box [#{coords}]/\" #{file} > #{fixed_tmp}"
    else
      cmd = "#{CONFIG[:sed]} #{SED_FLAG} \"s/(Media|Crop|Art|Bleed)Box( ?)\\[[0-9 \.]*?\\]/\\1Box\\2[#{coords}]/g\" #{file} > #{fixed_tmp}"
    end
    FEEDBACK.debug(cmd)
    unless system(cmd)
      @error = true
      FEEDBACK.warning "Failed to fix -- Abort"
      return false
    end
    return fixed_tmp
  end
  
  def trimbox_for_single_page(file, options = {})
    # File must be an uncompressed PDF
    FEEDBACK.verbose("  Retrieving trimbox coords...")
    # Have encountered issues with pdfs created with pdf_extract.rb
    # cmd = "#{CONFIG[:awk]} '{ where = match($0, /^<<\\/CropBox \\[(.*)\\]/, arr); if (where != 0) { print arr[1] }}' #{file}"
    if @pdftk_version >= 1.44
      cmd = "#{CONFIG[:awk]} '/pdftk_PageNum 1$/, /MediaBox/ { where = match($0, /^\\/TrimBox \\[(.*)\\]/, arr); if (where != 0) { print arr[1] }}' #{file}"
    else
      cmd = "#{CONFIG[:awk]} '/^<<\\/pdftk_PageNum 1\\// { where = match($0, /TrimBox ?\\[([0-9 \\.]*?)\\]/, arr); if (where != 0) { print arr[1] }}' #{file}"
    end
    FEEDBACK.debug(cmd)
    coords = `#{cmd}`.strip
    FEEDBACK.debug(coords)
    coords
  end
  
  def fix_trimbox(file, options = {})
    # File must be an uncompressed PDF
    page1 = (options[:page1].is_a?(Integer) && options[:page1] >= 1 ? options[:page1] : 1)
    page2 = (options[:page2].is_a?(Integer) && options[:page2] >= 1 ? options[:page2] : 1)
    coords1 = trimbox(file, :page => page1)
    coords2 = trimbox(file, :page => page2)
    fixed_tmp = FileTool.random_filename(TMP_DIR, "temp_uncompressed_fixed", "pdf")
    FEEDBACK.verbose("  Performing trimbox search/replace in PDF...")
    cmd = "#{CONFIG[:sed]} #{SED_FLAG} \"/pdftk_PageNum #{page1}$/,/pdftk_PageNum/ s/(Media|Crop|Art|Bleed)Box \\[.*\\]/\\1Box [#{coords1}]/\" #{file} | #{CONFIG[:sed]} #{SED_FLAG} \"/pdftk_PageNum #{page2}$/,/pdftk_PageNum/ s/(Media|Crop|Art|Bleed)Box \\[.*\\]/\\1Box [#{coords2}]/\" > #{fixed_tmp}"
    FEEDBACK.debug(cmd)
    unless system(cmd)
      @error = true
      FEEDBACK.error "Failed to fix trimbox -- Abort"
      return false
    end
    return fixed_tmp
  end
  
  def trimbox(file, options = {})
    # File must be an uncompressed PDF
    page = (options[:page].is_a?(Integer) && options[:page] >= 1 ? options[:page] : 1)
    FEEDBACK.verbose("  Retrieving trimbox coords for page #{page}...")
    cmd = "#{CONFIG[:awk]} '/pdftk_PageNum #{page}$/, /MediaBox/ { where = match($0, /^\\/TrimBox \\[(.*)\\]/, arr); if (where != 0) { print arr[1] }}' #{file}"
    FEEDBACK.debug(cmd)
    coords = `#{cmd}`.strip
    FEEDBACK.debug(coords)
    coords
  end
  
  def fix_mediabox(file, options = {})
    # File must be an uncompressed PDF
    page1 = (options[:page1].is_a?(Integer) && options[:page1] >= 1 ? options[:page1] : 1)
    page2 = (options[:page2].is_a?(Integer) && options[:page2] >= 1 ? options[:page2] : 1)
    coords1 = mediabox(file, :page => page1)
    coords2 = mediabox(file, :page => page2)
    fixed_tmp = FileTool.random_filename(TMP_DIR, "temp_uncompressed_fixed", "pdf")
    FEEDBACK.verbose("  Performing mediabox search/replace in PDF...")
    cmd = "#{CONFIG[:sed]} #{SED_FLAG} \"/pdftk_PageNum #{page1}$/,/pdftk_PageNum/ s/(Trim|Crop|Art|Bleed)Box \\[.*\\]/\\1Box [#{coords1}]/\" #{file} | #{CONFIG[:sed]} #{SED_FLAG} \"/pdftk_PageNum #{page2}$/,/pdftk_PageNum/ s/(Trim|Crop|Art|Bleed)Box \\[.*\\]/\\1Box [#{coords2}]/\" > #{fixed_tmp}"
    unless system(cmd)
      @error = true
      FEEDBACK.error "Failed to fix trimbox -- Abort"
      return false
    end
    return fixed_tmp
  end
  
  def mediabox(file, options = {})
    # File must be an uncompressed PDF
    page = (options[:page].is_a?(Integer) && options[:page] >= 1 ? options[:page] : 1)
    FEEDBACK.verbose("  Retrieving media box coords for page #{page}...")
    cmd = "#{CONFIG[:awk]} '/pdftk_PageNum #{page}$/, /MediaBox/ { where = match($0, /^\\/MediaBox \\[(.*)\\]/, arr); if (where != 0) { print arr[1] }}' #{file}"
    FEEDBACK.debug(cmd)
    coords = `#{cmd}`.strip
    FEEDBACK.debug(coords)
    coords
  end
  
  def compress(file, target, options)
    # File must be an uncompressed PDF
    FEEDBACK.verbose("  Compressing PDF...")
    if options[:meta]
      system("#{CONFIG[:pdftk]} #{file} update_info #{options[:meta]} output #{target} compress")
    else
      system("#{CONFIG[:pdftk]} #{file} output #{target} compress")
    end
  end
  
  def cast_to_integer_and_confirm(str)
    value = str.to_i
    unless value > 0
      FEEDBACK.warning "Value is zero"
    end
    return value
  end
  
  def get_format_value(str, options = {})
    FEEDBACK.verbose("  Calculating format '#{str}'...")
    # [0] means to analyze the first page of the pdf, in case of a multipage pdf
    value = `#{CONFIG[:identify]} -format "#{str}" '#{self.path}[0]'`.strip
    unless value
      FEEDBACK.error "Failed to determine format value"
      value = nil
    end
    return value
  end
  
  def needs_cropping_fix?(options = {})
    page1 = (options[:page1].is_a?(Integer) && options[:page1] >= 1 ? options[:page1] : 1)
    page2 = (options[:page2].is_a?(Integer) && options[:page2] >= 2 ? options[:page2] : 2)
    FEEDBACK.verbose("  Verifying cropping...")
    width1 = width("#{self.path}[#{page1 - 1}]")
    width2 = width("#{self.path}[#{page2 - 1}]")
    # TODO: what if widths aren't properly retrieved, resulting in width1 = width2 = 0
    if width1 != width2
      FEEDBACK.warning "Pdf requires crop fix"
      FEEDBACK.debug("page #{page1} width (#{width1}) != page #{page2} width (#{width2})")
      needs_fix = true
    else
      needs_fix = false
    end
  end
  
  def convert(file, target, options = {})
    density = (options[:density].is_a?(Integer) && options[:density] >= 72 ? options[:density] : 150)
    color = (options[:color] && options[:color] == true)
    # Determine format to which we're converting (based on file extension)
    ext = FileTool.file_ext(target) || "unknown format"
    # Test format for compression requirement
    compress = ( /^tif{1,2}$/i.match(ext) ? "-compress LZW" : "" )
    # compress = ( /^jpe?g$/i.match(ext) ? "-compress JPEG -quality 96" : "" )
    # Test colorspace
    cmd = "#{CONFIG[:convert]} #{compress} -density #{density} '#{file}' -colorspace RGB '#{target}'"
    if color
      FEEDBACK.verbose("  Determining colorspace...")
      # [0] means to analyze the first page of the pdf, in case of a multipage pdf
      colorspace = `#{CONFIG[:identify]} -verbose '#{file}[0]' | #{CONFIG[:awk]} '/Colorspace/ {print $2}'`.strip
      if colorspace == 'CMYK'
        FEEDBACK.verbose("  CMYK detected...\n")
        cmd = "#{CONFIG[:convert]} #{compress} -colorspace CMYK -density #{density} '#{file}' -colorspace RGB '#{target}'"
      end
    end
    FEEDBACK.verbose("  Converting to #{ext.upcase}...")
    FEEDBACK.debug(cmd)
    unless system(cmd)
      FEEDBACK.error "Failed to convert #{file}"
      return false
    end
    target
  end
  
  def crop(target, density_in, width_in, height_in, crop_x_in, crop_y_in, width_out, density)
    color = true
    # Test colorspace
    cmd = "#{CONFIG[:convert]} -density #{density_in} '#{self.path}' -crop #{width_in}x#{height_in}+#{crop_x_in}+#{crop_y_in} -resize #{width_out} -density #{density} -colorspace RGB '#{target}'"
    if color
      FEEDBACK.verbose("  Determining colorspace...")
      # [0] means to analyze the first page of the pdf, in case of a multipage pdf
      colorspace = `#{CONFIG[:identify]} -verbose '#{self.path}[0]' | #{CONFIG[:awk]} '/Colorspace/ {print $2}'`.strip
      if colorspace == 'CMYK'
        FEEDBACK.verbose("  CMYK detected...\n")
        cmd = "#{CONFIG[:convert]} -colorspace CMYK -density #{density_in} '#{self.path}' -crop #{width_in}x#{height_in}+#{crop_x_in}+#{crop_y_in} -resize #{width_out} -density #{density} -colorspace RGB '#{target}'"
      end
    end
    # Determine format to which we're converting (based on file extension)
    # This only works if it's not converted to pdf format
    ext = FileTool.file_ext(target) || "unknown format"
    if ext == 'pdf'
      temp = target.sub(/pdf$/, 'jpg')
      cmd = cmd.sub(/'#{target}'$/, "'#{temp}'")
      FEEDBACK.debug(cmd)
      unless system(cmd)
        FEEDBACK.error "Failed to convert #{self.path}"
        return false
      end
      convert(temp, target, :density => density, :color => false)
      FileTool.remove(temp)
    else
      FEEDBACK.verbose("  Converting to #{ext.upcase}...")
      FEEDBACK.debug(cmd)
      unless system(cmd)
        FEEDBACK.error "Failed to convert #{self.path}"
        return false
      end
    end
    target
  end
  
end

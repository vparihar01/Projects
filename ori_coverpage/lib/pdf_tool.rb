# PdfTool module
# implementation of PDF manipulation methods used by coverpage projects
#
# Requires pdftoolkit installed - see http://www.accesspdf.com/pdftk/
# pdftk must be in the search path
# Requires PDF::Writer (gem install pdf-writer)
# http://ruby-pdf.rubyforge.org/pdf-writer/

require 'pdf/writer'
require 'RMagick'
require 'digest'

module PdfTool
  # checks the pdftk version
  def self.check_pdftk
    pdftk_cmd = "#{CONFIG[:pdftk]} --version"
    pdftk_version = %x[#{pdftk_cmd}].to_s.scan(/pdftk (\d+).(\d+)/).join(".")
    raise ArgumentError, "PdfBlender: missing pdftk! your pdftk configuration (CONFIG[:pdftk] = #{CONFIG[:pdftk]}) points to a missing command. please revise config or install pdftk.", caller if pdftk_version.blank?
    # raise ArgumentError, "PdfBlender: your pdftk version (#{pdftk_version}) is not recent enough. Minimum version 1.41 is required.", caller if pdftk_version < "1.41"
    # Rails.logger.warn("PdfBlender: your pdftk version (#{pdftk_version}) is not the recommended 1.44. you might experience errors. if so, upgrade your pdftk") if pdftk_version < "1.44"
    pdftk_version
  end

  unless defined?(PDF_TOOL_OK)  # avoid constant redefinitions
    check_pdftk              # start with verification of pdftk
    VERSION = '0.3'
    PDF_TOOL_OK = true            # signal that PdfTool is done with constant definitions
  end

  class PdfBlender
    unless defined?(PDF_BLENDER_OK)   # avoid constant redefinitions
      WATERMARK_METHODS = [:stamp, :background]
      DEFAULT_WATERMARK_METHOD = :stamp
      DEFAULT_TEXT_PROPERTIES = {
        :font => "Times-Roman",
        :font_size => 16,
        :text_angle => 0,
        :justification => :center,
        :alignment => :bottom,
        :font_color => "#333333",
        :vmargin => 0,
        :hmargin => 0
      }
      DEFAULT_PERMISSIONS = ["ScreenReaders","CopyContents"]
      DEFAULT_ENCRYPTION = nil
      DEFAULT_PAPER = 'A4'
      DEFAULT_ORIENTATION = :portrait
      PDF_BLENDER_OK = true     # signal that PdfBlender is done with constant definitions
    end

    attr_accessor :source, :target, :overwrite, :append, :input_pw, :owner_pw, :user_pw, :text_properties, :permissions, :pages

    def initialize(params={})
      # Set and assign default attributes values
      params = {:source => nil, :target => nil, :overwrite => false, :input_pw => nil, :owner_pw => nil, :user_pw => nil, :text_properties => DEFAULT_TEXT_PROPERTIES, :permissions => DEFAULT_PERMISSIONS}.merge(params)
      params.keys.each { |k| self.send("#{k}=", params[k]) }
      
      @logger = Rails.logger
      
      raise ArgumentError, "PdfBlender: source file '#{@source}' not found", caller unless @source && File.exist?(@source)
      raise ArgumentError, "PdfBlender: target file '#{@target}' exists (overwrite not enabled)", caller if @target && File.exist?(@target) && !@overwrite
      @logger.debug("# PdfBlender: instantiating... source:#{@source}; target:#{@target}")
      if @target.nil?
        @target = create_temp_file
        @logger.debug("# PdfBlender: created temp file: target = #{@target}'")
      elsif File.exist?(@target) && @overwrite
        FileUtils.rm(@target)
      end
      
      # check attributes
      verify_properties
      calculate_pages
    end
    
    def watermark(watermark_file = nil, watermark_text = nil, watermark_method = DEFAULT_WATERMARK_METHOD)
      unless watermark_text.blank?
        # save original source and target
        old_source = @source
        old_target = @target
        # merge watermark file and text
        @source = create_watermark_file(watermark_text)
        @target = nil
        watermark_file = watermark_with_file(watermark_file, watermark_method)
        # revert to original source and target
        @source = old_source
        @target = old_target
      end
      if watermark_file && File.exist?(watermark_file)
        watermark_with_file(watermark_file, watermark_method)
      else
        @source
      end
    end
    
    # adds a given watermark to the original
    def watermark_with_file(watermark_filename, watermark_method = DEFAULT_WATERMARK_METHOD)
      test_file(@source, "source file not found")
      @target = create_temp_file if @target.blank?
      if watermark_filename && File.exist?(watermark_filename)
        unless WATERMARK_METHODS.include?(watermark_method.to_sym)
          @logger.debug "# PdfBlender: Unknown watermark method #{watermark_method} - falling back to #{DEFAULT_WATERMARK_METHOD}..."
          watermark_method = DEFAULT_WATERMARK_METHOD
        end
        pdftk_cmd = "#{CONFIG[:pdftk]} #{@source} #{watermark_method} #{watermark_filename} output #{@target}"
        @logger.debug("# PdfBlender: executing '#{pdftk_cmd}'")
        system(pdftk_cmd)
        test_file(@target, "failed to watermark")
      else
        # If no watermark file, return copy of source
        FileUtils.copy_file(@source, @target, :force => true)
        @target
      end
    end
    
    # adds a given text-based watermark to the original
    # the method assembles a pdf using the specified text
    # and uses that file to watermark the original pdf.
    #
    # <tt>:text</tt>::  The text to be printed on the original (adjust @text_properties for options such as font, color, size)
    def watermark_with_text(text, watermark_method = DEFAULT_WATERMARK_METHOD)
      # if no text defined, simply return source
      return @source if text.blank?
      # create watermark file, then apply it to source
      temp_filename = create_watermark_file(text)
      watermark_with_file(temp_filename, watermark_method)
    end

    # method extracts a single page from original and creates a thumbnail image of it
    #
    # output format is defined by the filename specified in <tt>@target</tt>
    # if target not specified, a JPEG file with random name will be generated
    # 
    # Input parameters
    # <tt>page</tt>::       the page of the PDF the thumbnail should be for
    # <tt>geometry</tt>::   the desired geometry of the page (see RMagick's geometry string: http://studio.imagemagick.org/RMagick/doc/imusage.html#geometry
    def thumb(page, geometry)
      test_file(@source, "source file not found")
      @target = create_temp_file(:ext => '.jpg') if @target.blank?
      
      temp_filename = create_temp_file
      # TODO verify if 'page' specifies a valid page; otherwise fall back to 1
      pdftk_cmd = "#{CONFIG[:pdftk]} #{@source} cat #{page} output #{temp_filename}"
      #TODO verify results, throw errors
      @logger.debug("# PdfBlender: executing '#{pdftk_cmd}'")
      system(pdftk_cmd)
      # now we should have a single-page PDF to generate our thumbnail from
      # TODO generate thumbnail
      ilist = Magick::ImageList.new(temp_filename)
      #TODO scale image according to input parameters
      #ilist.scene = 1
      ilist.first.change_geometry!(geometry) { |cols, rows, img|
        img.resize!(cols, rows)
      }
      ilist.first.write(@target)
    end

    # method should extract pages from @source
    # input parameters
    # <tt>page_array</tt>: array containing the pages that should be extracted
    #                       eg. [1, 2, 3, 4, 5] - pages 1, 2, 3, 4, 5
    #                           [1, 3] - pages 1 and 3
    def extract(page_array)
      test_file(@source, "source file not found")
      @target = create_temp_file if @target.blank?
      
      # verify that pages within page_array do not exceed total number of pages in PDF
      page_array.uniq.delete_if {|page| page.to_i > @pages}
      # proceed with extraction
      if page_array.any?
        pdftk_cmd = "#{CONFIG[:pdftk]} #{@source} cat #{page_array.join(' ')} output #{@target}"
        @logger.debug("# PdfBlender: executing '#{pdftk_cmd}'")
        system(pdftk_cmd)
      else
        # array is empty. copy entire file
        FileUtils.mv(@source, @target, :force => true)
      end
      test_file(@target, "failed to extract")
    end

    # method should secure/protect the @source PDF
    # resulting file is @target, passwords should be provided in @owner_pw and @user_pw
    def secure
      test_file(@source, "source file not found")
      @target = create_temp_file if @target.blank?
      
      # TODO implement encrypting options
      pdftk_cmd = "#{CONFIG[:pdftk]} #{@source}"
      pdftk_cmd += " output #{@target}"
      pdftk_cmd += " owner_pw \"#{@owner_pw}\"" unless @owner_pw.blank?
      pdftk_cmd += " user_pw \"#{@user_pw}\"" unless @user_pw.blank?
      if @permissions.any?
        @permissions.each { |permission| pdftk_cmd += " allow #{permission}" }
      end
      @logger.debug("# PdfBlender: executing '#{pdftk_cmd}'")
      system(pdftk_cmd)
      test_file(@target, "failed to secure")
    end

    # method should create array that specifies pages to be extracted from @source
    # input parameters
    # <tt>front_pages</tt>: integer specifying number of pages to be taken from front of pdf
    # <tt>back_pages</tt>: integer specifying number of pages to be taken from back of pdf
    # NB: if front_pages + back_pages > pages, both will be reduced until < pages
    def get_page_array(front_pages=19, back_pages=10)
      # NB: ebooks have even number of pages (interior spreads + first/last endsheet + front/back cover)
      #     page 1 of an ebook is the cover, page 2 is the endsheet, 
      #     page 3 is the first page of the first signature 
      #     the last page is the back cover, the second to last page is the endsheet, 
      #     the third to last page is the last page of the last signature 
      # Important: want to extract 'spreads' of the ebook. spread always starts with an even number. 
      #     the first spread is front endsheet + first page of first signature (pages 2 and 3 of ebook) 
      #     the last spread is last page of last signature + last endsheet (pages -3 and -2 of ebook) 
      # Conclusion: front_pages must be odd. back_pages must be even.
      front_pages += 1 if front_pages % 2 == 0 # ensure front_pages is odd
      back_pages += 1 if back_pages % 2 > 0 # ensure back_pages is even
      while front_pages + back_pages >= @pages
        front_pages -= 2
        back_pages -= 2
        @logger.debug("front_pages=#{front_pages}, back_pages=#{back_pages}")
      end
      @logger.debug("final: front_pages=#{front_pages}, back_pages=#{back_pages}")
      ((1..front_pages).to_a + ((@pages-back_pages)..@pages).to_a).uniq
    end
    
    protected
    
      # calculate number of pages in source file
      def calculate_pages
        pdftk_cmd = "#{CONFIG[:pdftk]} #{@source} dump_data | grep NumberOfPages | grep -o -e \"\\([0-9]*\\)$\""
        @pages = %x[#{pdftk_cmd}].to_i
      end
      
      # check existence of file, return path if ok, raise error if not
      def test_file(path, msg="file does not exist")
        raise "PdfBlender: #{msg}" unless path && File.size(path) > 0
        path
      end
      
      # verify text properties
      def verify_properties
        if @text_properties
          DEFAULT_TEXT_PROPERTIES.keys.each {|k| @text_properties[k] = DEFAULT_TEXT_PROPERTIES[k] if @text_properties[k].blank?}
        else
          @text_properties = DEFAULT_TEXT_PROPERTIES
        end
      end
      
      # create temp file for output
      def create_temp_file(params={})
        params = {:base => 'rand', :ext => '.pdf'}.merge(params)
        Tempfile.new([params[:base], params[:ext]], Rails.root.join(CONFIG[:pdftool_temp_dir])).path
      end
      
      # create watermark file from text
      # the method assembles a pdf with created text into a temporary pdf file
      #
      # <tt>:watermark_text</tt>::  The text to be printed on the watermark (adjust @text_properties for options such as font, color, size)
      def create_watermark_file(text)
        return nil if text.blank?
        verify_properties

        temp_pdf = PDF::Writer.new(:paper => DEFAULT_PAPER, :orientation => DEFAULT_ORIENTATION )

        # set the watermark text properties.
        temp_pdf.fill_color( Color::RGB.from_html(@text_properties[:font_color]) )
        temp_pdf.select_font(@text_properties[:font])

        # count lines (line ending designated by \n's in the text)
        linecount = text.split("\n").size

        # set the initial cursor position
        xoffs = @text_properties[:hmargin].blank? ? 0 : @text_properties[:hmargin]
        #yoffs = (temp_pdf.text_line_width(text, @text_properties[:font_size]) / temp_pdf.page_width + linecount - 1) * @text_properties[:font_size] + @text_properties[:vmargin]
        yoffs = 0
        case @text_properties[:alignment]
          when :bottom
            yoffs = (linecount - 1 ) * @text_properties[:font_size] + @text_properties[:vmargin]
          when :top
            yoffs = temp_pdf.page_height - @text_properties[:font_size] - @text_properties[:vmargin]
          when :center
            yoffs = (temp_pdf.page_height + (linecount - 1 ) * @text_properties[:font_size] ) / 2
        end
        # make sure the text won't go off-page
        yoffs = 0 if yoffs < 0
        yoffs = temp_pdf.page_height if yoffs > temp_pdf.page_height

        text.each do |tmptxt|
          while tmptxt != "" do       # repeat until the text buffer is not empty
            # print out what fits, the remainder will go back to tmptxt
            tmptxt = temp_pdf.add_text_wrap(xoffs, yoffs, temp_pdf.page_width, tmptxt, @text_properties[:font_size], @text_properties[:justification], @text_properties[:text_angle])
            yoffs -= @text_properties[:font_size]                  # position to the next line
          end
        end

        # save the watermark file
        temp_filename = create_temp_file
        temp_pdf.save_as(temp_filename)
        temp_pdf.close_object

        # return watermark file
        test_file(temp_filename, "failed to create watermark file")
      end

  end

end

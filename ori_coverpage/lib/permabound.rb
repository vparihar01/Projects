class Permabound
  # uncomment the next line if you installed hpricot from the gem
  # require 'rubygems'
  # require 'hpricot'
  require 'open-uri'
  
  attr_reader :attributes, :error
  
  REQUIRES_DEEP_SCRAPE = %w(lccn word_count annotation)
  
  def initialize(isbn, verbose=false, debug=false)
    @error = false
    @isbn = isbn
    @debug = debug
    @verbose = verbose
    # hash to transpose permabound field names to cherrylake field names
    @columns = {
      "isbn_13" => "isbn",
      "dewey" => "dewey",
      "copyright" => "copyright",
      "quiz" => "alsquiznr",
      "points" => "alspoints",
      "reading_level" => "alsreadlevel",
      "pages" => "pages",
      "word_count" => "word_count",
      "lccn" => "lccn",
    }
    @attributes = {}
    unless @title = Title.find_by_isbn(@isbn)
      puts "! Error: Title not found"
      @error = true
    end
    scrape
  end
  
  def update_title
    return false if @error
    puts "  Updating title..." if @verbose
    if @attributes.any?
      current = @title.attributes.reject{|k,v| !@attributes.has_key?(k)}
      puts "    Current => #{current.inspect}" if @verbose
      puts "    Changes => #{@attributes.inspect}" if @verbose
      @title.update_attributes(@attributes) unless @debug
    else
      puts "    Update skipped: No valid data" if @verbose
    end
  end
  
  protected
  
    def get(url)
      begin
        # open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
        response = nil
        open(url, "User-Agent" => "Ruby/#{RUBY_VERSION}",
          "Referer" => "http://milkfarmproductions.com/") { |f| response = f.read }
        # HPricot RDoc: http://code.whytheluckystiff.net/hpricot/
        doc = Hpricot(response)
      rescue Exception => e
        puts "Error: #{e} (#{url})", ""
        exit(1)
      end
      doc
    end
    
    def scrape
      # only update columns that don't currently have data
      @columns.delete_if {|k,v| !@title.send(v).blank? }
      unless @columns.any?
        puts "  Retrieval skipped: Record already complete" if @verbose
        @error = true
        return false
      end
      retrieved = {}
      puts "  Retrieving permabound data for #{@isbn}..." if @verbose
      doc = get("http://www.perma-bound.com/Advanced-Search.do?qt=isbn&q=#{@isbn}")
      title = doc.at("title").inner_html
      if match = title.match(/No Search Results Found/)
        puts "Error: #{title}"
        @error = true
        return false
      end
      if match = title.match(/Search for ISBN/)
        puts "Error: #{title} (Multiple results found)"
        @error = true
        return false
      end
      (doc/"div.viewDetail-Detail").each do |x|
        label = (x/"span.detailKey").inner_html.strip.gsub(/\:/,'').gsub(/ /,'_').downcase
        if value = x.at('//span[@class="detailKey"]')
          value = value.next.to_s.strip.gsub(/[#\n\r\t]/,'')
          retrieved[label] = value
        end
      end
      unless retrieved.size > 0
        puts "Error: Unexpected results (no data)"
        @error = true
        return false
      end
      if retrieved['accelerated_reader'].nil?
        retrieved['quiz'] = nil
        retrieved['points'] = nil
      else
        if match = retrieved['accelerated_reader'].match(/quiz:\s+(\d+)/)
          retrieved['quiz'] = match[1]
        end
        if match = retrieved['accelerated_reader'].match(/points:\s+([0-9.]+)/)
          retrieved['points'] = match[1]
        end
      end
      # puts "  Retrieved => #{retrieved.inspect}"
      # print "  Comparing ISBN values..." if @verbose
      # if @title.isbn == retrieved['isbn_13'].gsub!(/-/, '')
      #   puts "  Match." if @verbose
      # else
      #   puts "  NO match! #{retrieved['isbn_13']}" if @verbose
      #   exit 1
      # end
      @columns.each do |k,v|
        @attributes[v] = retrieved[k] if retrieved[k]
      end
      clean
      return retrieved
    end
    
    def clean
      puts "  Cleaning data..." if @verbose
      @attributes['isbn'].gsub!(/-/, '') if @attributes.has_key?('isbn')
      @attributes['copyright'].gsub!(/[^0-9]/, '').to_i if @attributes.has_key?('copyright')
      @attributes['alspoints'] = @attributes['alspoints'].to_f if @attributes.has_key?('alspoints')
      @attributes['alsreadlevel'] = @attributes['alsreadlevel'].to_f if @attributes.has_key?('alsreadlevel')
      @attributes['pages'].gsub!(/[^0-9]/, '').to_i if @attributes.has_key?('pages')
      @attributes['word_count'].gsub!(/[^0-9]/, '').to_i if @attributes.has_key?('word_count')
      # check
      @attributes.delete_if {|k,v| @attributes[k].blank? || @attributes[k] == 0 }
    end
    
    def check
      puts "  Checking data..." if @verbose
      @columns.each do |k,v|
        puts "#{v} = #{@attributes[v]} !" if @attributes[v].blank? || @attributes[v] == 0
      end
    end
    
end

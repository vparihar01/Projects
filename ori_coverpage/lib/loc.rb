class Loc
  require 'open-uri'
  
  attr_reader :attributes, :error
  
  def initialize(isbn, verbose=false, debug=false, force_search_by_isbn=false)
    @error = false
    @isbn = isbn
    @debug = debug
    @verbose = verbose
    @force_search_by_isbn = force_search_by_isbn
    # hash to transpose LOC field names to db field names
    @columns = {
      "dewey_class_no" => "dewey",
      "lc_classification" => "lcclass",
      "lc_control_no" => "lccn",
    }
    @attributes = {}
    unless @title = Title.find_by_isbn(@isbn)
      puts "! Error: Title not found"
      @error = true
    end
    scrape unless @error
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
      puts "  Retrieving LOC data for #{@isbn}..." if @verbose
      search_by_isbn = false
      if @title.lccn.blank? || @force_search_by_isbn == true
        url = "http://catalog.loc.gov/cgi-bin/Pwebrecon.cgi?v3=1&Search%5FArg=#{@isbn}&Search%5FCode=STNO&CNT=1&SID=1"
      else
        url = "http://lccn.loc.gov/#{@title.lccn}"
      end
      puts "    #{url}" if @verbose
      doc = get(url)
      title = doc.at("title").inner_html
      if (doc/"table.error").any? || (doc/"div.nohits").any?
        puts "! Error: Page not found"
        puts "    #{url}"
        @error = true
        return false
      end
      (doc/"th").each do |x|
        label = x.inner_html.strip.gsub(/\:/,'').gsub(/ /,'_').gsub(/\.$/,'').downcase
        el = x.next
        until el.is_a?(Hpricot::Elem) || el.is_a?(NilClass)
          el = el.next
        end
        if el.is_a?(Hpricot::Elem)
          value = el.inner_html.strip.gsub(/[#\n\r\t]/,'')
          value = value.gsub(/<br \/>$/,'') unless value.blank?
          value = value.gsub(/<span class="noprint">(.*?)<\/span>/,'') unless value.blank?
          value = value.split('<br />') if value.match('<br />')
        else
          value = nil
        end
        retrieved[label] = value
      end
      unless retrieved.size > 0
        puts "! Error: Unexpected results (no data)"
        @error = true
        return false
      end
      # puts "  Retrieved: " if @verbose
      # retrieved.each {|k, v| puts "    #{k} = #{v.inspect}"} if @verbose
      unless @title.lccn.blank?
        # if we searched by isbn, values will automatically match
        print "  Comparing ISBN values..." if @verbose
        temp = retrieved["isbn"].is_a?(Array) ? retrieved["isbn"][0] : retrieved["isbn"]
        temp = temp.to_s.gsub(/ \(.*\)$/, '')
        if @title.isbn == temp
          puts "  Match" if @verbose
        else
          puts "  NO match! #{temp}" if @verbose
          @error = true
          return false
        end
      end
      @columns.each do |k,v|
        @attributes[v] = retrieved[k] unless retrieved[k].blank?
      end
      clean
      return retrieved
    end
    
    def clean
      puts "  Cleaning data..." if @verbose
      @attributes.delete_if {|k,v| @attributes[k].blank? || @attributes[k] == 0 }
      check
    end
    
    def check
      puts "  Checking data..." if @verbose
      @columns.each do |k,v|
        puts "#{v} = #{@attributes[v]} !" if @attributes[v].blank? || @attributes[v] == 0
      end
    end
    
end

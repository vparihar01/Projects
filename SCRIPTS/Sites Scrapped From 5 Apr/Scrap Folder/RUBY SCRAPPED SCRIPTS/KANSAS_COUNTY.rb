=begin
     Kansas.rb is a Ruby file/crawler which Scraps the Offender Details from Kansas County
    URL => ""http://www.doc.ks.gov/kasper/index_html?YesNo=Please+Wait..."!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into DatabaseSTATE = "Kansas"
STATE="Kansas"
COUNTY = "Kansas County"
CITY = "Kansas"

BASE = "http://www.doc.ks.gov/kasper/index_html?YesNo=Please+Wait..."	# Base URL to get the details 
DETAILEDURL = "http://www.doc.ks.gov/kasper/index_html?YesNo=Please+Wait..."	# Detail URL for posting data's

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)	# Initilaized the Scrape Class
arrest = DFG::Arrest.new()

doc=scrape.get(BASE)			# Opens Base URL

"a".upto("z") do |x|
  location = "http://165.201.143.205/kasper2/offenders.asp?RaceName=&GenderName=&SupervisionCountyName=&ConvictionCountyName=&LocationName=&lastname=#{x}&firstname=&middlename=&includealias=0&kdoc=&box1=&box2=&box3=&thumbnails=1&race=&gender=&BirthRangeStart=&AGErangestart=&AGErangeend=&convictionCounty=&supervisionCounty=&Location=&kbi=&Facility="
  doc1 = Nokogiri::HTML(open(location)) rescue ""	# Nokogiri to open the page
  #image1 = doc1.xpath("//table[@cellpadding='2']/tbody/tr/td[1]/a/img/@src")
  name = doc1.xpath("//table[@cellpadding='2']/tbody/tr/td[4]") #.first.gsub("\r\n\t\t", " ")
  links = doc1.xpath("//table[@cellpadding='2']/tbody/tr/td[4]/a/@href") #.text.gsub("\r\n\t\t\t", "")

  links.each_with_index do |link, index|
    arrest = DFG::Arrest.new()	 # Initilaizing object of Arrest Class
    inner_link = link.text.gsub("\r\n\t\t\t", "")	# Extracts the link removing white spaces
    inner_doc = Nokogiri::HTML(open(inner_link)) rescue ""	# opens Page
    arrest.name = name[index].text#.split("\302").first.gsub("\r\n\t\t", " ")	# removes trailing spaces
    arrest.image1 = inner_doc.xpath("//table[@align='right']/tr[1]/td[1]/a/img/@src")[0].text rescue ""
    image2=inner_doc.xpath("//table[@align='right']/tr[1]/td[1]/a/img/@src")[1].text rescue ""

   if !image2.empty?
	    p arrest.image2=image2
    end
    
    begin
      temp_date = inner_doc.xpath("//table[@class='offender'][6]/tr[1]/td[3]").text.gsub(", ","-").gsub(" ","-")
      arrest.date = temp_date != "" ? Date.strptime(temp_date, "%B-%d-%Y").to_s : Date.today.to_s	# Inserts Date
    rescue
      arrest.date = Date.today.to_s
    end
    desc = inner_doc.xpath("//table[@class='offender'][6]/tr[1]/td[6]").text	# Inserts Description
    bond = 0
    arrest.add_charge(desc, bond)

    scrape.add(arrest)	# Executes Inserted Datas
    scrape.commit()		# Commits executed Datas
  end
end



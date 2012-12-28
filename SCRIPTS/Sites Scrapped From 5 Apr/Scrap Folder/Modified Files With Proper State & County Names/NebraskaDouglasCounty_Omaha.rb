=begin
     Nebraska	Douglas County-Omaha.rb is a Ruby file/crawler which Scraps the Offender Details from Nebraska	Douglas County-Omaha
    URL => "http://www.omahasheriff.org/"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Nebraska"
COUNTY = "Douglas County"
CITY = "Omaha"
BASE ="http://www.omahasheriff.org"	 # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)	# Initializing object of Scrape Class
doc = Nokogiri::HTML(open(BASE))			# Nokogiri Opens the Base url for Scrapping
baseurl="http://www.omahasheriff.org"
size=doc.css('#mainbody').css('#rightcolumn').css('.moduletable').size
 arrest = DFG::Arrest.new()	# Initilaizing object of Arrest Class
(3..size-1).each{ |l|
  detailedurl=doc.css('.moduletable')[l].css('a').to_s.split('href=').last.split('>').first.reverse.chop.reverse.chop	# grabs the detailed url
  DETAILEDURL=baseurl+detailedurl										# Appends the full path 
  doc1 = Nokogiri::HTML(open(DETAILEDURL))								# Nokogiri Opens the Detailedurl for Scrapping
  image1=doc1.css('.moduletable')[1].css('img').to_s.split('src=').last.split('">').first.reverse.chop.reverse	# scraps the image
  name=doc1.css('.moduletable')[1].css('p').inner_html.split('Name: ').last.split('<br>').first		# scraps the name
  charge=doc1.css('.moduletable')[1].css('p').inner_html.split('Charge: ').last.split('<br>').first	# scraps the charges
  image=baseurl+image1
     arrest.name=name	# inserts the name
    arrest.image1=image		# inserts the image
    bond=0		
    arrest.add_charge(charge, 0)		# insersts the charges
    scrape.add(arrest)	# Executes the inserted records
    scrape.commit()	# Commits the Executed Datas
}
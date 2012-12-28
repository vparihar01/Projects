=begin
      Arkansas Sebastian County-Fort Smith.rb is a Ruby file/crawler which Scraps the Offender Details(Image, Name, Description) from Sebastian County-Fort Smith
      (http://publicrecords.onlinesearches.com/AR_Sebastian.htm, OR, http://sebastiancountysheriff.com/wanted.php OR http://mugshots.com/US-Counties/Arkansas/Sebastian-County-AR/)!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")      # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Arkansas"
COUNTY = "Sebastian County"
CITY = "Fort Smith"
BASE = "http://sebastiancountysheriff.com/wanted.php"       # Base url to scrape the datas.
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)             # Initilaized the Scrape Class
doc = scrape.get(BASE) 								 # Opens the Page and stores it into doc(VARIABLE)
link=[]                                             						# link array to store the links
doc.xpath('//a[contains(concat( " ", @class, " " ), concat( " ", "ptitles", " " ))]').each {|o| link << o['href']}             # Stores the Href contents into link.
link.each { |i|
next_page="http://sebastiancountysheriff.com/#{i}"			# scrapes the next page link
document= scrape.get(next_page)								# opens the next page
 desc=document.xpath('//strong').inner_html					# scrapes the Description.
 name= document.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "frame", " " ))]//table//b').text   # Scrapes the Name
 img=document.css('img').to_html.to_s.split('src=')[2].split('"')[1]			#Scrapes the Image
arrest = DFG::Arrest.new() 										   # Creates an object of Arrest Class.
image="http://sebastiancountysheriff.com/#{img}"					
arrest.image1 = image											# Processes Image using Quick Magick present in Scrape.rb file
arrest.name = name											# inserts the name into DB
bond = 0
    arrest.add_charge(desc, bond)    									# Adds Charges into DB.
    scrape.add(arrest)                                 							# Executes the Details.
    scrape.commit()												# Commits the Inserted Data's.
}
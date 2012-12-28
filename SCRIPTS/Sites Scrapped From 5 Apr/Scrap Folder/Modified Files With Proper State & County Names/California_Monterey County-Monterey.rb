=begin
      California_Monterey County Monterey is a Ruby file/crawler which Scraps the Offender Details from Monterey County
    URL => "http://www.co.monterey.ca.us/sheriff/wanted.htm" !!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb") # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Californina"
COUNTY = "Monterey County"
CITY = "Monterey"
	BASE="http://www.co.monterey.ca.us/sheriff/wanted.htm"  # Base url to scrape the datas.
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)             # Initilaized the Scrape Class
	doc = scrape.get(BASE)								# Opens the Page and stores it into doc(VARIABLE)
	img=[]		# img array to store image links
	name=[]          #Name Array to store names
	charge=[]        # charges Array to store charges
total=[]                    # Total datas
	doc.css('#AutoNumber4 tr').each {|i| 
		  i.css('img').each {|u| img << u['src']}		 # Scraps the img links and pushes it into img array.
		  i.css('font').each { |p| total << p.inner_html}       # Scraps the total count
	  }
	(0..total.size-1).step(2).each { |i|
name <<  total[i].split('<br>').first rescue ""                           # Scraps the name and stores it into an array name
 charge << total[i].split('<br>').last.strip! rescue ""                 # Scrapes the Charges and stores it into charge
	}
	  
for i in 0..img.size-1
	arrest = DFG::Arrest.new()                                                   # Initialized an Object of Arrest class.
	arrest.image1 = arrest.image2="http://www.co.monterey.ca.us/sheriff/#{img[i]}" rescue "" # Image is being processed and stored into DB
	arrest.name = name[i] rescue ""                                         # Name is stored into DB
	bond=0
	desc=charge[i] rescue ""          # desc is scrapped and stored into DB
	arrest.add_charge(desc, bond)    # Adds charges
scrape.add(arrest)                               # executes the DB
scrape.commit()					# Commits the datas
end
	  
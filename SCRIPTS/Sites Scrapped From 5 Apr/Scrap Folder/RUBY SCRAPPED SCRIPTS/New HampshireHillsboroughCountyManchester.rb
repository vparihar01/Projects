=begin
     New Hampshire-HillsboroughCounty-Manchester.rb is a Ruby file/crawler which Scraps the Offender Details from New Hampshire-HillsboroughCounty-Manchester
    URL => "http://www.hcsonh.us/wanted.php"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "New Hampshire"
COUNTY = "Hillsborough County"
CITY = "Manchester"
	BASE="http://www.hcsonh.us/wanted.php"			# Base URL to get the details 
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		   # Initializing object of Scrape Class
	docs = scrape.get(BASE)								# gets Offender page to get total page count
	image =[]
	name=[]
	date=[]
	charges=[]
	arrest = DFG::Arrest.new() 						  # Initilaizing object of Arrest Class
	total_pages=docs.css('.pc_desc')[0].inner_html.split('of').last.to_i rescue ""	# Gets Total Pages
	j=0
	for i in 1..total_pages
		
		BASE="http://www.hcsonh.us/wanted.php?item=#{j}"		# Base URL
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)						# gets Offender page for scrapping
#image
 doc.css('.subtable a:nth-child(1) img').each {|i|
image <<  i['src']			# Scraps Image
}
#name
count=doc.css('td:nth-child(2)').size
(5..count-3).step(6) {|i|
name << doc.css('td:nth-child(2)')[i].inner_html		# scraps Name
}
# Charges
count=doc.css('.subtable td:nth-child(4)').size
(2..count-1).step(6) {|i|
charges <<  doc.css('.subtable td:nth-child(4)')[i].inner_html		# Scraps Charges
}

# date
count=doc.css('.subtable td:nth-child(4)').size
(4..count-1).step(6) {|i|
date << doc.css('.subtable td:nth-child(4)')[i].inner_html		# Scraps Date
}

for i in 0..image.size-1
	
	link="http://www.hcsonh.us/#{image[i]}"
	elink=URI.encode(link)  
	arrest.image1 = arrest.image2=elink rescue ""		# Inserts Image
	
	if !name[i].nil?
	 arrest.name = name[i] rescue "" #Inserts Name
	end

	if !date[i].nil? 
	 arrest.date = DateTime.strptime(date[i], "%m/%d/%Y") rescue "" 	# inserts Date
	 end
	bond=0
	desc=charges[i] rescue "" 		
	arrest.add_charge(desc, bond)    # Inserts Charges
scrape.add(arrest)		# Executes the Inserted Data's
scrape.commit()		# Commits the Executed data's
end
	  j += 8		# increments the counter by 8
	  end
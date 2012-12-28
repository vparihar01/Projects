=begin
      Albama_DothanCounty.rb is a Ruby file/crawler which Scraps the Offender Details from Dothan County
      URL => "http://www.doc.state.al.us/inmsearch.asp"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")      	# Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Alabama"										
COUNTY = "Dothan County"
CITY = "Dothan"
	BASE="http://www.doc.state.al.us/inmresults.asp?AIS=&FirstName=&LastName="   # Base URL for Scrapping the datas.
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)      # Initializing an Object of Scrape class.
	arrest = DFG::Arrest.new()				# Initializing an Object of Arrest class .
	doc = scrape.get(BASE)						# Opens the Base Url.
	 count=doc.css('td:nth-child(2)').size					        # Takes the total data Count.
	 for i in 1..count-1
		 name=doc.css('td:nth-child(2)')[i].text		# Scraps the Name.
		
        arrest.name = name							# Stores the name into Database.
	bond=0										# As Bond amt is not available it is set to Zero.
	desc= "Nil"									# As Description is not available it is set to NIL.
	arrest.add_charge(desc, bond)    					# Adds charges to DB.
scrape.add(arrest)									# Executes the details.
scrape.commit()									# Commits the data into DB.
		 
	 end
	 
	
=begin
     MISSOURI County.rb is a Ruby file/crawler which Scraps the Offender Details from MISSOURI County
    URL => "https://web.mo.gov/doc/offSearchWeb/"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "MISSOURI"
COUNTY = "MISSOURI County"
CITY = "MISSOURI"
BASE="https://web.mo.gov/doc/offSearchWeb/search.jsp" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
DETAIL="http://www.nd.gov/docr/offenderlkup/nameprocessor.asp" # Detail URL for posting data's
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
for i in "a".."z"					# loops through a to z from first name to open the offender details page
	post_args= {
	'Submit'=>'Submit',							# POSTING ARGUMENTS
	'lastName'=>"#{i}"
	}
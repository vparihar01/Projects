=begin
     NORTH DAKOTA County.rb is a Ruby file/crawler which Scraps the Offender Details from NORTH DAKOTA County
    URL => "http://www.nd.gov/docr/offenderlkup/index.asp"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "NORTH DAKOTA"
COUNTY = "NORTH DAKOTA County"
CITY = "NORTH DAKOTA"
BASE="http://www.nd.gov/docr/offenderlkup/index.asp" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
DETAIL="http://www.nd.gov/docr/offenderlkup/nameprocessor.asp" # Detail URL for posting data's
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
for i in "a".."z"					# loops through a to z from first name to open the offender details page
	post_args= {
	'Submit'=>'Submit',							# POSTING ARGUMENTS
	'lastName'=>"#{i}"
	}
	
	document=scrape.post(DETAIL,post_args)					#Posting Arguments to open Offender Page
	document.css('td:nth-child(1) a').each {|i|
	offender_page=URI.encode("http://www.nd.gov/docr/offenderlkup/#{i['href']}") rescue ""
	off_detail=scrape.get(offender_page) rescue ""
	p name=off_detail.css('#column2 td')[1].inner_html rescue ""				# Scraps Name
	p img=off_detail.css('#offender').to_html.split('"')[1].gsub('%20','') rescue ""	# Scraps Image
	p image=URI.encode("http://www.nd.gov/docr/offenderlkup/#{img}") rescue ""
	
	arrest.image1=image rescue ""			# INSERTS IMAGE
	arrest.name=name				# INSERTS NAME
	arrest.add_charge(NIL,0)			# INSERTS CHARGES
	scrape.add(arrest)				# EXECUTES INSERTED DATAS
	scrape.commit()				# COMMITS EXECUTED DATAS
	}
end

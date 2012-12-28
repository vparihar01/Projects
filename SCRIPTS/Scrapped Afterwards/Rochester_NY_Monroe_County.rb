=begin
     Rochester_NY_Monroe_County.rb is a Ruby file/crawler which Scraps the Offender Details from Monroe County
    URL => "http://www.criminaljustice.ny.gov/SomsSUBDirectory/search_index.jsp?offenderSubmit=true&LastName=&County=28&Zip=&Submit=Search"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Rochester"
COUNTY = "Monroe County"
CITY = "New York"
BASE="http://www.criminaljustice.ny.gov/SomsSUBDirectory/search_index.jsp?offenderSubmit=true&LastName=&County=28&Zip=&Submit=Search"  # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		# Initializing object of Scrape Class
 arrest = DFG::Arrest.new()							 # Initilaizing object of Arrest Class
doc= scrape.get(BASE)								# gets Offender page
links=Array.new
 doc.css("#mainContent a").each { |link|
links << link["href"] rescue ""								# links with id are accumulated here
links.uniq! rescue ""										# Unique Links are Scrapped
}
links.each { |i|
p next_link=URI.encode("http://www.criminaljustice.ny.gov#{i}") rescue ""		# Link url is encoded
document=scrape.get(next_link)									# page is opened
fname= document.css("table:nth-child(5) tr:nth-child(2) td:nth-child(2)").inner_html rescue ""	# First Name is Scrapped
mname= document.css("tr:nth-child(4) td:nth-child(2)").inner_html rescue ""					# Middle name is Scrapped
lname= document.css("table:nth-child(5) tr:nth-child(3) td:nth-child(2)").inner_html rescue ""	# Last Name is Scrapped
img= document.css("td:nth-child(5) img")[0]["src"] rescue ""									# image Id is scrapped
p date= document.css("table:nth-child(15) td:nth-child(1)").inner_html rescue ""					# date is Scrapped
mname="" if mname.nil?		
desc=document.css("table:nth-child(17) td:nth-child(7)").inner_html rescue ""					# Offences Are scrapped
arrest.name=fname+","+mname +" "+lname rescue ""										# Name is inserted
arrest.image1=URI.encode("http://www.criminaljustice.ny.gov/SomsSUBDirectory/#{img}")	# Image is inserted
arrest.date=Date.parse(date) if !date.nil?											# date is inserted
arrest.add_charge(desc,0)														# Description is inserted
scrape.add(arrest)								# Datas are executed
scrape.commit()								# Executed datas are commited
}
 
 

 
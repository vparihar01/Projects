=begin
     Florida	Orange County-Orlando.rb is a Ruby file/crawler which Scraps the Offender Details from Orange County-Orlando
    URL => "http://apps.ocfl.net/bailbond/Default.asp"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Florida"
COUNTY = "Orange County"
CITY = "Orlando"
BASE="http://apps.ocfl.net/bailbond/Default.asp"   # Base URL to get the details 
DETAIL ="http://apps.ocfl.net/bailbond/Default.asp" # Detail URL for posting data's
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)    	   # Initializing object of Scrape Class
 arrest = DFG::Arrest.new()							  # Initilaizing object of Arrest Class
 for i in "a".."z"									# loops through a to z from first name to open the offender details page
post_args = {										# posts Arguments
 'SEARCHTEXT'=> "#{i}",							# passing values i.e a,b,c .... z
 'Search'=>'Search'
 }
 
 document=scrape.post(BASE, post_args)
 document.css('td.ten').css('a').each { |u|
  link="http://apps.ocfl.net/#{u['href']}"			# Encodes the offender link
 open=scrape.get(link)								# gets Offender page
  name=open.css('b font').inner_html rescue ""			# gets Name
  img=open.css('tr td#content img')[0]['src'] rescue ""	# Scraps image
  image="http://apps.ocfl.net/bailbond/#{img}"		# Encodes the full path	
 date=open.css('#Table5 tr:nth-child(7) td:nth-child(2) font').inner_html rescue ""	# scraps date
 amt=open.css('#Table6 tr:nth-child(3) td:nth-child(2) font').inner_html rescue ""	# scraps bond amount
 description=open.css('#Table6 tr:nth-child(7) td:nth-child(2) font:nth-child(1)').inner_html rescue ""	# scraps description
if description.include?('<br>')
 description=description.split('<br>').first rescue ""  # Scraps the description without <br> tags	
end
arrest.image1 = arrest.image2=image rescue ""
	arrest.name = name rescue ""
	if !date.empty?
	 arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""	# scraps date 
	 end
	bond=amt
	descr=description
	arrest.add_charge(descr, bond)    	# Adds Charges
	scrape.add(arrest)				# Executes the inserted Record's
	scrape.commit()				# Commits the Executed Data's

 }
 end
 

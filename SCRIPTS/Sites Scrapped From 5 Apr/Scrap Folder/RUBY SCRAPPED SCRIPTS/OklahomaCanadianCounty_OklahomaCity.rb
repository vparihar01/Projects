=begin
     Oklahoma	Canadian County- Oklahoma City.rb is a Ruby file/crawler which Scraps the Offender Details from Oklahoma	Canadian County- Oklahoma City
    URL => "http://docapp065p.doc.state.ok.us/servlet/page?_pageid=395&_dad=portal30&_schema=PORTAL30"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "OKLAHOMA"
COUNTY = "Canadian County"
CITY = "Oklahoma"
baseurl="http://docapp065p.doc.state.ok.us"	 # Base URL to get the details 
BASE = 	"http://docapp065p.doc.state.ok.us/servlet/page?_pageid=393&_dad=portal30&_schema=PORTAL30"	 # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)	 # Initializing object of Scrape Class
arrest = DFG::Arrest.new()		  # Initilaizing object of Arrest Class
for j in "a".."z"		# loops through a to z from first name to open the offender details page
	
k=0
end_no=0
start_no=0
bond=0
DETAILEDURL="http://docapp065p.doc.state.ok.us/servlet/page?_pageid=393&_dad=portal30&_schema=PORTAL30&SearchMode=Basic&first_name=#{j}&SearchAll=ALL"	# Detail URL for posting data's

doc1 = scrape.get(DETAILEDURL)	# opens the page

begin
	if k!=0
		extendedurl="&rowstart="+"#{start_no}"+"&totalcount="+"#{end_no}"
		DETAILEDURL1=DETAILEDURL+extendedurl
		doc1 = scrape.get(DETAILEDURL1)		# opens the offender detail page
	else
	  doc1 = scrape.get(DETAILEDURL)
	end

	no_persons=doc1.css('.PortletText1:nth-child(2)').size	# Get the offender count

	 for i in 0..no_persons-1		# loops over each offender data
		 
		search_detail=doc1.css('.PortletText1:nth-child(2)')[i].css('a').to_html.split('href=').last.split('>').first.gsub("\"","").gsub('&amp;','&').split('%').first
		detailed_url=URI.encode("http://docapp065p.doc.state.ok.us#{search_detail}")

		doc2 = scrape.get(detailed_url)
 		
		
		image=doc2.css(':nth-child(3) .RegionHeaderColor img').css('img').to_s.split('src=').last.split(' height').first.gsub("\"","") rescue ""
			if (image!="")
				image1=baseurl+image
				arrest.image1=image1 		# inserts Image
			end
		p name=doc2.css('.PortletText1').inner_html.to_s.split('<br>').first rescue ""
 		arrest.name=name		# inserts Name
		
		size=doc2.css(':nth-child(5) td:nth-child(3)').css('td').css('font').size
			for p in 0..size-1
				desc=doc2.css(':nth-child(5) td:nth-child(3)').css('td').css('font')[p].inner_html
				arrest.add_charge(desc, 0)	# inserts Charges
			end

		scrape.add(arrest)	# Executes the Inserted Data's
		scrape.commit() # Commits the Executed Data's

	end

	k=k+1
	end_no=doc1.css('.RegionHeaderColor td td tr:nth-child(1) td').inner_html.to_s.split('n').last.split('of').last.strip!.to_i rescue ""
	start_no=doc1.css('.RegionHeaderColor td td tr:nth-child(1) td').inner_html.to_s.split('n').last.split('of').first.split(' ').last.to_i rescue ""

 end while start_no < end_no 

end

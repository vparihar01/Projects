=begin
     Indiana	Evansville.rb is a Ruby file/crawler which Scraps the Offender Details from Indiana Evansville
    URL => "http://www.in.gov/apps/indcorrection/ofs/ofs"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Indiana"
COUNTY = "Evansville  County"
CITY = "Evansville"
bond=0
BASE="http://www.in.gov/apps/indcorrection/ofs/ofs" 	 # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		# Initializing object of Scrape Class
arrest = DFG::Arrest.new()							 # Initilaizing object of Arrest Class
for i in "a".."z"									# loops through a to z from first name to open the offender details page
	
 DETAILEDURL="http://www.in.gov/apps/indcorrection/ofs/ofs?lname=&fname=#{i}&search1.x=65&search1.y=56"		# Detailed URL for posting data's
 doc = scrape.get(DETAILEDURL)						# opens the DETAILED URL
 page_no=doc.css('td:nth-child(4) font').css('a').size		# collects the page no(total)
 pages=doc.css('td:nth-child(4) font').css('a').each {|p| 
 params=p.to_s.split('?').last.split('>').first.gsub('&amp;','&').chop	# collects params
 URL1="http://www.in.gov/apps/indcorrection/ofs/ofs?#{params}"	# passes params as path for URL
 doc1 = scrape.get(URL1)						# scraps URL1
 size=doc1.css('td:nth-child(2) a').size	# takes the size
(0..size-1).each{|p|
		params1=doc1.css('a')[p].to_s.split('?').last.split('>').first.gsub('&amp;','&').chop
		URL2="http://www.in.gov/apps/indcorrection/ofs/ofs?#{params1}"
		doc2= scrape.get(URL2)
		firstname=doc2.css('tr:nth-child(1) tr:nth-child(3) td:nth-child(2)').css('font').inner_html rescue ''	# scraps First Name
		middlename=doc2.css('tr:nth-child(1) tr:nth-child(4) td:nth-child(2)').css('font').inner_html rescue '' # Scraps middle name
		lastname=doc2.css('tr:nth-child(1) tr:nth-child(5) td:nth-child(2) font').inner_html rescue ''		# Scraps LastName
		name2=[middlename,firstname].join(' ').squeeze(' ')	# Squeezes the middle and first name
		name=[lastname,name2].join(',').squeeze(' ')	# squeezes name2 and last name
		if (name!="")
		  arrest.name = name # inserts name
		end
		descr=doc2.css('tr:nth-child(3) tr:nth-child(3) td:nth-child(2) font').inner_html rescue ''	# inserts Description
		descr.split(',').each{|desc|
		if (desc!="")
			arrest.add_charge(desc, bond)			# inserts charges
		end
		}
		scrape.add(arrest)		# Executes the inserted Records
		scrape.commit()		# Commits the Executed Datas
 }
}
end
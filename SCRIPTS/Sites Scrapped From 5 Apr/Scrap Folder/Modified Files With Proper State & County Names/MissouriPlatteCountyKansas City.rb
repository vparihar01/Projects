=begin
     Missouri	Platte County-KansasCity.rb is a Ruby file/crawler which Scraps the Offender Details from Missouri	Platte County-KansasCity
    URL => "http://plattesheriff.org/most-wanted"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Missouri"
COUNTY = "Platte County"
CITY = "Kansas City"
BASE="http://plattesheriff.org/most-wanted"	# Base Url to scrape data
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)	# Scrape object initialized
doc = scrape.get(BASE)	# opens the Base url

count=doc.css('tr td').size

(3..count-1).step(4) {|i|
arrest = DFG::Arrest.new() 
next_link=doc.css('tr td')[i].css('a')[0]['href']	# Scrapes the next_link to get the offender details
DETAIL="http://plattesheriff.org#{next_link}" 	# Detail url to post data
docs = Nokogiri::HTML(open(DETAIL))				# Nokogiri opens the page to be scraped
image=docs.css('tr td')[0].css('img')[1]['src']		# Scraps Image
name=docs.css('tr td')[0].css('font').css('b').inner_html # scraps name
date=docs.css('table')[1].css('tr td')[11].inner_html.split('Entry Date:')	# scraps date
desc=docs.css('table')[1].css('tr td')[10].inner_html.split('<b>Wanted For:</b>').last	# scraps description
arrest.image1 = arrest.image2=image rescue ""	# Inserts Image
arrest.name = name	# inserts name
arrest.date=date	# Inserts date

#desc = charge
bond = 0	
	
arrest.add_charge(desc, bond)	# Insersts Charges
scrape.add(arrest)	# executes Inserted datas
scrape.commit()	# commits executed datas
}




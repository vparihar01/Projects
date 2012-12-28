=begin
     Missouri	Platte County-KansasCity.rb is a Ruby file/crawler which Scraps the Offender Details from Missouri	Platte County-KansasCity
    URL => "http://plattesheriff.org/most-wanted"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Missouri"
COUNTY = "Platte County"
CITY = "Kansas City"
BASE="http://plattesheriff.org/most-wanted"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
doc = scrape.get(BASE)

count=doc.css('tr td').size

(3..count-1).step(4) {|i|
arrest = DFG::Arrest.new() 
next_link=doc.css('tr td')[i].css('a')[0]['href']
DETAIL="http://plattesheriff.org#{next_link}" 
docs = Nokogiri::HTML(open(DETAIL))
image=docs.css('tr td')[0].css('img')[1]['src']
name=docs.css('tr td')[0].css('font').css('b').inner_html
date=docs.css('table')[1].css('tr td')[11].inner_html.split('Entry Date:')
desc=docs.css('table')[1].css('tr td')[10].inner_html.split('<b>Wanted For:</b>').last
arrest.image1 = arrest.image2=image rescue ""
arrest.name = name
arrest.date=date

#desc = charge
bond = 0

arrest.add_charge(desc, bond)
scrape.add(arrest)
scrape.commit()
}




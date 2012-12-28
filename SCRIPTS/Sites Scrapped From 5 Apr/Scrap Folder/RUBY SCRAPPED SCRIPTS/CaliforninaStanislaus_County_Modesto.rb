=begin
     Californina	Stanislaus County-Modesto.rb is a Ruby file/crawler which Scraps the Offender Details from Stanislaus County
    URL => "http://www.stancrimetips.org/mostwanted/"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Californina"
COUNTY = "Stanislaus County"
CITY = "Modesto"
	BASE="http://www.stancrimetips.org/mostwanted/"	  # Base URL to get the details 
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		  # Initializing object of Scrape Class
	doc = scrape.get(BASE)			# opens the Base url 
arrest = DFG::Arrest.new()   # Initilaizing object of Arrest Class
total_pages=doc.css('#MainContent table').last.css('a').last.to_s.split('pg=').last.scan(/\d/).join('').to_i		# calculates the total pages available

for i in 1..total_pages		
	
BASE="http://www.stancrimetips.org/mostwanted/default.asp?pg=#{i}"	# loops through each page and scraps the Base url
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
docs = scrape.get(BASE)
count=doc.css('#MainContent table').size
(0..count-2).step(4) {|i|
	 img=docs.css('#MainContent table')[i].css('tr td')[0].css('a').css('img').to_html.split('"/').last.split('"').first rescue ""	# Scraps Images
	 image="http://www.stancrimetips.org/#{img}" rescue ""				
	  name=docs.css('#MainContent table')[i].css('tr td')[6].inner_html rescue ""		# Scraps Name
	 desc=docs.css('#MainContent table')[i].css('p').inner_html.split('</b>').last rescue ""	# Scraps descriptiion
	 date=docs.css('#MainContent table')[i].css('center').inner_html.split('</b>').last rescue ""	# Scraps date
	 
	arrest.image1 = arrest.image2=image rescue ""	# inserts Image
        arrest.name = name		# inserts Name
	bond=0
	if !date.nil? || !date.empty? 
	 arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""	# Inserts Date
	 end
	arrest.add_charge(desc, bond)    # Inserts Charges
scrape.add(arrest)	# Executes Inserted Records
scrape.commit()	# Commits Executed Datas

}
end

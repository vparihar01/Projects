require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Lubbock"
COUNTY = "Lubbock County Sheriff's Office"
CITY = "Lubbock"
	BASE="https://apps.co.lubbock.tx.us/jailrosters/activejailprt.aspx"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
	arrest = DFG::Arrest.new()
	count=doc.css('table#roster').css('tr td').css('table tr').css('tr').css('td').size
	(0..count-1).step(3) {|i|
	
	arrest.name=doc.css('table#roster').css('tr td').css('table tr').css('tr').css('td')[i].inner_html
	scrape.add(arrest)
	scrape.commit()
         }
	arrest.image1 = "https://apps.co.lubbock.tx.us/jailrosters/activejailprt.aspx"	rescue ''
	
	
	
	
	
	
require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Californina"
COUNTY = "Stanislaus County"
CITY = "Modesto"
	BASE="http://www.stancrimetips.org/mostwanted/"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)

total_pages=doc.css('#MainContent table').last.css('a').last.to_s.split('pg=').last.scan(/\d/).join('').to_i

for i in 1..total_pages
	
BASE="http://www.stancrimetips.org/mostwanted/default.asp?pg=#{i}"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
docs = scrape.get(BASE)
count=doc.css('#MainContent table').size
(0..count-2).step(4) {|i|
arrest = DFG::Arrest.new() 
	 img=docs.css('#MainContent table')[i].css('tr td')[0].css('a').css('img').to_html.split('"/').last.split('"').first rescue ""
	 image="http://www.stancrimetips.org/#{img}" rescue ""
	  name=docs.css('#MainContent table')[i].css('tr td')[6].inner_html rescue ""
	 desc=docs.css('#MainContent table')[i].css('p').inner_html.split('</b>').last rescue ""
	 date=docs.css('#MainContent table')[i].css('center').inner_html.split('</b>').last rescue ""
	 
	arrest.image1 = arrest.image2=image rescue ""
        arrest.name = name
	bond=0
	if !date.nil?
	 arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""
	 end
	arrest.add_charge(desc, bond)    
scrape.add(arrest)
scrape.commit()

}
end

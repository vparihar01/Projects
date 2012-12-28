require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "New Mexico"
COUNTY = "Canadian County"
CITY = "Oklahoma City"
	BASE="http://app.bernco.gov/custodylist/ReleaseListInter.aspx?id=ALL"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
	links=[]
doc.css('#GridView1 a').each {|p|
links <<  URI.encode("http://app.bernco.gov/custodylist/#{p['href']}")
}
for i in 0..links.size-1
BASE=links[i]
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	dcmt = scrape.get(BASE)
	
	
	img=dcmt.css('#GridView1_Panel , #ViewOffImage')[1]['src']
	 image=URI.encode("http://app.bernco.gov/custodylist/#{img}")
	 name=dcmt.css('#GridView1_Panel , #ViewOffImage')[0].css('span').inner_html.split(/\d/)[8]
	content= dcmt.css('#GridView1_Panel , #ViewOffImage')[0].css('span').inner_html.split(',').first
	   day=content.split('/')[0] rescue ""
	   month=content.split('/')[1] rescue ""
	   year=content.split('/').last.to_i rescue ""
	  date= "#{day}/#{month}/#{year}"
	arrest = DFG::Arrest.new()
 arrest.image1=image
	 arrest.name=name
	arrest.date=DateTime.strptime(date, "%m/%d/%Y") rescue ""
	scrape.add(arrest)
        scrape.commit()
	
end

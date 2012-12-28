require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "OKLAHOMA"
COUNTY = "Spartanburg County"
CITY = "Spartanburg"
baseurl="http://docapp065p.doc.state.ok.us"
BASE = 	"http://docapp065p.doc.state.ok.us/servlet/page?_pageid=393&_dad=portal30&_schema=PORTAL30"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

for j in "a".."z"
	
k=0
end_no=0
start_no=0
bond=0
DETAILEDURL="http://docapp065p.doc.state.ok.us/servlet/page?_pageid=393&_dad=portal30&_schema=PORTAL30&SearchMode=Basic&first_name=#{j}&SearchAll=ALL"

doc1 = scrape.get(DETAILEDURL)

begin
	if k!=0
		extendedurl="&rowstart="+"#{start_no}"+"&totalcount="+"#{end_no}"
		DETAILEDURL1=DETAILEDURL+extendedurl
		doc1 = scrape.get(DETAILEDURL1)
	else
	  doc1 = scrape.get(DETAILEDURL)
	end

	no_persons=doc1.css('.PortletText1:nth-child(2)').size

	 for i in 0..no_persons-1
		 
		search_detail=doc1.css('.PortletText1:nth-child(2)')[i].css('a').to_html.split('href=').last.split('>').first.gsub("\"","").gsub('&amp;','&').split('%').first
		detailed_url=URI.encode("http://docapp065p.doc.state.ok.us#{search_detail}")

		doc2 = scrape.get(detailed_url)
 		arrest = DFG::Arrest.new()
		
		image=doc2.css(':nth-child(3) .RegionHeaderColor img').css('img').to_s.split('src=').last.split(' height').first.gsub("\"","") rescue ""
			if (image!="")
				image1=baseurl+image
				arrest.image1=image1 
			end
		name=doc2.css('.PortletText1').inner_html.to_s.split('<br>').first rescue ""
 		arrest.name=name
		
		size=doc2.css(':nth-child(5) td:nth-child(3)').css('td').css('font').size
			for p in 0..size-1
				desc=doc2.css(':nth-child(5) td:nth-child(3)').css('td').css('font')[p].inner_html
				arrest.add_charge(desc, 0)
			end

		scrape.add(arrest)
		scrape.commit()

	end

	k=k+1
	end_no=doc1.css('.RegionHeaderColor td td tr:nth-child(1) td').inner_html.to_s.split('n').last.split('of').last.strip!.to_i rescue ""
	start_no=doc1.css('.RegionHeaderColor td td tr:nth-child(1) td').inner_html.to_s.split('n').last.split('of').first.split(' ').last.to_i rescue ""

 end while start_no < end_no 

end

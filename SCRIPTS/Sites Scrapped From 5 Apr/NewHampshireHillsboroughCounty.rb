require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "New Hampshire"
COUNTY = "Hillsborough County"
CITY = "Manchester"
	BASE="http://www.hcsonh.us/wanted.php"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	docs = scrape.get(BASE)
	image =[]
	name=[]
	date=[]
	charges=[]
	
	total_pages=docs.css('.pc_desc')[0].inner_html.split('of').last.to_i rescue ""
	j=0
	for i in 1..total_pages
		
		BASE="http://www.hcsonh.us/wanted.php?item=#{j}"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
#image
 doc.css('.subtable a:nth-child(1) img').each {|i|
image <<  i['src']
}
#name
count=doc.css('td:nth-child(2)').size
(5..count-3).step(6) {|i|
name << doc.css('td:nth-child(2)')[i].inner_html
}
# Charges
count=doc.css('.subtable td:nth-child(4)').size
(2..count-1).step(6) {|i|
charges <<  doc.css('.subtable td:nth-child(4)')[i].inner_html
}

# date
count=doc.css('.subtable td:nth-child(4)').size
(4..count-1).step(6) {|i|
date << doc.css('.subtable td:nth-child(4)')[i].inner_html
}

for i in 0..image.size-1
	arrest = DFG::Arrest.new() 
	link="http://www.hcsonh.us/#{image[i]}"
	elink=URI.encode(link)  
	arrest.image1 = arrest.image2=elink rescue ""
	
	if !name[i].nil?
	arrest.name = name[i] rescue ""
	end
	if !date[i].nil?
	 arrest.date = DateTime.strptime(date[i], "%m/%d/%Y") rescue ""
	 end
	bond=0
	desc=charges[i] rescue ""
	arrest.add_charge(desc, bond)    
scrape.add(arrest)
scrape.commit()
end
	  j += 8
	  end
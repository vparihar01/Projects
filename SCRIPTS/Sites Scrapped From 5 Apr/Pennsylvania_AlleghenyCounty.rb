require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Pennsylvania"
COUNTY = "Allegheny County"
CITY = "Pittsburgh"
	BASE="http://sheriffalleghenycounty.com/mostwanted_top20.html"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)

	image =[]
	name=[]
	desc=[]
	#image
	count=doc.xpath('//img').size
	(9..count-4).step(1) {|i|

 image<<doc.xpath('//img')[i]['src']
	 }
	
doc.css('.style6').each{|i|
na=i.inner_html
 name << na.split('">').last.split('</').first}

doc.css('#apDiv74 .style1 , #apDiv70 .style8, #apDiv82 .style1, #apDiv118 .style3, #apDiv58 .style3, #apDiv54 .style1, #apDiv50 .style8, #apDiv46 .style1').each{|i|
description=i.inner_html
desc << description.split('">').last.split('</').first
}

doc.css('#apDiv42 .style1 , #apDiv38, #apDiv86 .style1, #apDiv30 .style1, .style9, #apDiv94 .style4, #apDiv18 .style8, #apDiv14 .style1').each{|i|
d=i.inner_html
desc << d.split('">').last.split('</').first
}

doc.css('#fug12charges .style4 , #fug2charges .style3, #fug11charges .style8, #fug1charges').each{|i|
d=i.inner_html
desc << d.split('">').last.split('</').first
}


#~ #desc = charge
for i in 0..name.size-1
img="http://sheriffalleghenycounty.com/#{image[i]}"
arrest = DFG::Arrest.new() 
 arrest.image1 = arrest.image2=img rescue ""
 nam=name[i].split(' ')
arrest.name = nam[0].to_s + ', ' + nam[1].to_s
bond = 0
 arrest.add_charge(desc[i], bond)
scrape.add(arrest)
scrape.commit()
end




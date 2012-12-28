=begin
    Pennsylvania	Allegheny County-Pittsburgh.rb is a Ruby file/crawler which Scraps the Offender Details from Pennsylvania	Allegheny County-Pittsburgh
    URL => "http://sheriffalleghenycounty.com/mostwanted_top20.html"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Pennsylvania"
COUNTY = "Allegheny County"
CITY = "Pittsburgh"
	BASE="http://sheriffalleghenycounty.com/mostwanted_top20.html"		# Base URL to get the details 
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)			# Initializing object of Scrape Class
	doc = scrape.get(BASE)									# Opens the Base Url for scrapping offender details
	arrest = DFG::Arrest.new() 								  # Initilaizing object of Arrest Class
	# Initializing Arrays where data will be stored temporarily
	image =[]
	name=[]
	desc=[]
	#image
	count=doc.xpath('//img').size
	(9..count-4).step(1) {|i|

 image<<doc.xpath('//img')[i]['src']	rescue ""	# scraps Image
	 }
	
doc.css('.style6').each{|i|
na=i.inner_html
 name << na.split('">').last.split('</').first  rescue ""
 }		# scraps Name

doc.css('#apDiv74 .style1 , #apDiv70 .style8, #apDiv82 .style1, #apDiv118 .style3, #apDiv58 .style3, #apDiv54 .style1, #apDiv50 .style8, #apDiv46 .style1').each{|i|
description=i.inner_html
desc << description.split('">').last.split('</').first rescue ""	# scraps description
}

doc.css('#apDiv42 .style1 , #apDiv38, #apDiv86 .style1, #apDiv30 .style1, .style9, #apDiv94 .style4, #apDiv18 .style8, #apDiv14 .style1').each{|i|
d=i.inner_html
desc << d.split('">').last.split('</').first rescue ""
}

doc.css('#fug12charges .style4 , #fug2charges .style3, #fug11charges .style8, #fug1charges').each{|i|
d=i.inner_html
desc << d.split('">').last.split('</').first rescue ""
}


#~ #desc = charge
for i in 0..name.size-1
img="http://sheriffalleghenycounty.com/#{image[i]}"
 arrest.image1 = arrest.image2=img rescue ""	# Inserts Image
 nam=name[i].split(' ')	
arrest.name = nam[0].to_s + ', ' + nam[1].to_s rescue ""	# inserts Name
bond = 0
 arrest.add_charge(desc[i], bond)	# inserts Charges
scrape.add(arrest)	# Executes Inserted Records
scrape.commit()	# Commits Executed Datas
end




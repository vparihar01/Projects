require 'mysql'
require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Cuyahoga"
COUNTY = "Cuyahoga County Sheriff"
CITY = "Cuyahoga Office"
m=1
n=2
	BASE="http://blog.cleveland.com/metro/2010/05/cuyahoga_county_sheriffs_most_2.html"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
	description=doc.css('div.entry-content p')
        doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "small", " " ))]').each { |i|
	image = i.css('img').map { |i|  i['src']}
if image.size > 0  
    arrest = DFG::Arrest.new() 
    #image
    arrest.image1 = image[0].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    #arrest.image2 = image[0].gsub('medium','large').gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    #name
   name=i.css('span.caption').inner_html.split(',')[0]
   arrest.name = name
    #date
    #~ date = nil
    #~ arrest.date = date    
    #charges
   
   desc = description[m..n][1].inner_html
    m=m+2
    n=n+2
    bond = 0
    arrest.add_charge(desc, bond)    
    scrape.add(arrest)
  end
  scrape.commit()
	}
	

















#html.linux body div#MasterContainer div#PageContent div#MainColumn div#ContentWellFull div.full_entry div#article div.entry-content p




#~ doc.xpath('//*[(@id = "block-system-main")]//*[contains(concat( " ", @class, " " ), concat( " ", "clearfix", " " ))]').each { |i| 
	#~ image = []
	#~ i.css('div.field-item a img').map {|u| image << u['src']}

 #~ }
 

#html.js body.html div#page-wrapper div#page div#main-wrapper div#main.clearfix div#middle div#content.column div.section div.region div#block-system-main.block div.block-content div#node-7.node div.field div.field-items div.field-item a img

#html.js body.html div#page-wrapper div#page div#main-wrapper div#main.clearfix div#middle div#content.column div.section div.region div#block-system-main.block div.block-content div#node-7.node div.content div.field div.field-items div.field-item p

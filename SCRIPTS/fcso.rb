require 'mysql'
require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "FCSO"
COUNTY = "Florence County Sherrifs Office"
CITY = "Sherrifs Office"

	BASE="http://www.fcsomostwanted.com/"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
       doc.xpath('//*[(@id = "block-system-main")]//*[contains(concat( " ", @class, " " ), concat( " ", "clearfix", " " ))]').each { |i| 
	image = []
	i.css('div.field-item a img').map {|u| image << u['src']}
if image.size > 0  
    arrest = DFG::Arrest.new() 
    #image
    puts arrest.image1 = image[0].gsub('medium','large').gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    puts arrest.image2 = image[0].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    #name
    name=i.css('div.field-item p').inner_html.split(',')[0]
   puts  arrest.name = name
    #date
    #~ date = nil
    #~ arrest.date = date    
    #charges
    puts desc = i.css('div.field-item p').inner_html.split(',')[3].strip! if (i.css('div.field-item p').inner_html.split(',')[3])
    bond = 0
    arrest.add_charge(desc, bond)    
    scrape.add(arrest)
  end
  scrape.commit()
 }
 

#html.js body.html div#page-wrapper div#page div#main-wrapper div#main.clearfix div#middle div#content.column div.section div.region div#block-system-main.block div.block-content div#node-7.node div.field div.field-items div.field-item a img

#html.js body.html div#page-wrapper div#page div#main-wrapper div#main.clearfix div#middle div#content.column div.section div.region div#block-system-main.block div.block-content div#node-7.node div.content div.field div.field-items div.field-item p

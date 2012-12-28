require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Arkansas"
COUNTY = "Sebastian County"
CITY = "Fort Smith"
BASE = "http://sebastiancountysheriff.com/wanted.php"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
doc = scrape.get(BASE)
link=[]
doc.xpath('//a[contains(concat( " ", @class, " " ), concat( " ", "ptitles", " " ))]').each {|o| link << o['href']}
link.each { |i|
next_page="http://sebastiancountysheriff.com/#{i}"
document= scrape.get(next_page)
 desc=document.xpath('//strong').inner_html
 name= document.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "frame", " " ))]//table//b').text
 img=document.css('img').to_html.to_s.split('src=')[2].split('"')[1]
arrest = DFG::Arrest.new() 
image="http://sebastiancountysheriff.com/#{img}"
arrest.image1 = image
arrest.name = name
bond = 0
    arrest.add_charge(desc, bond)    
    scrape.add(arrest)
    scrape.commit()
}
#!/opt/local/bin/ruby
require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Alabama"
COUNTY = "Houston"
CITY = "Gordon"

BASE = "http://www.bustedmugshots.com/alabama/gordon/antonio-teague/8740652"


scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)


arrestsTable = doc.css('table')
 arrestRows = arrestsTable[0].css('tr')

   row = arrestRows 
   image = doc.css('.profile_picture')[0].css('img')  
   if image.size > 0  
     arrest = DFG::Arrest.new()
    
    #~ #image
    arrest.image1 = arrest.image2 = image[0]['src'].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    
    #~ #name
    name = row.css('td')[1].inner_html.split('<br>')[0].split(' ')
    arrest.name = name[0] + ', ' + name[1]
    #~ #date
     date = row.css('td')[7].inner_html.split('<br>')[0].strip
     arrest.date = date.gsub("-","/")
    #~ #charge
    desc=arrestsTable[1].css('tr').css('tr')[1].text<<'\n'<<arrestsTable[1].css('tr').css('tr')[2].text<<'\n'<<arrestsTable[1].css('tr').css('tr')[3].text
    bond = 0
    arrest.add_charge(desc, bond)
    scrape.add(arrest)
scrape.commit()
  end
  #~ }


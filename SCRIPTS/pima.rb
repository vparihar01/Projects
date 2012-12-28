require 'mysql'
require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Pima"
COUNTY = "pima County"
CITY = " "
i=6
 # while  i !="No results found."
	BASE="http://www.pimasheriff.org/index.php?cID=1270&q=&sortBy=0&sortOrder=DESC&ccm_paging_p=#{i}"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
	puts arrests=doc.css("#main").inner_html.include?("No results found.")
	#~ arrestsTable = doc.css('ul.commScroll')
#~ arrestRows = arrestsTable.css('li')
#~ (1..arrestRows.size-1).each { |i|
  #~ row = arrestRows[i]  

 #~ image = row.css('span.commBody').css('img')  
  
  #~ if image.size > 0  
    #~ arrest = DFG::Arrest.new()
    
    #~ #image
    #~ arrest.image1 = arrest.image2 = image[0]['src'].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    #~ puts  row.css('span.commBody').css('p').inner_html.split('-')[0]
    #~ #name
    #~ name = row.css('span.commBody').css('p').inner_html.split('-')[0].split(' ')
    #~ arrest.name = name[0] + ', ' + name[1]
    #~ puts  row.css('span.commBody').css("h3").inner_html.split('Posted: ')[1].strip
    #~ #date
    #~ date = row.css('span.commBody').css("h3").inner_html.split('Posted: ')[1].strip 
    #~ arrest.date = date
    
    #~ #charges
    #~ desc = ""
    #~ bond = 0
    #~ arrest.add_charge(desc, bond)
    
    #~ scrape.add(arrest)
   
  #~ end
#~ }

#~ i+=1
	#end
scrape.commit()

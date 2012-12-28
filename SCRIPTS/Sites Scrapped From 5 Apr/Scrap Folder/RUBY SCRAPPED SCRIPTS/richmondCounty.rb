require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "South Carolina"
COUNTY = "Richmond County"
CITY = "South Carolina"
BASE = "http://www.co.richmond.va.us/most_wanted.htm"


scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)
 arrestsTable = doc.css('table')
 arrestRows = arrestsTable.css('tr')
	arrestsTable.css('tr').length
 (3..arrestRows.length-4).each{|r|
 if r%2==1
 row=arrestRows[r]
 image1=row.css('td')
 (0..image1.length-1).each {|i|
 if i%2==0
	if !image1[i].css('img')[0].nil?
 image=image1[i].css('img')[0]['src']
 name=arrestRows[r+1].css('td')[i].css('b').text
 desc=arrestRows[r+1].css('td')[i].inner_html.split('</b>')[1].split('.')[1]

arrest = DFG::Arrest.new()
		
		#~ #image
		 arrest.image1 = image

    #~ #name
    arrest.name = name
    
     #date
		arrest.date = Date.today.to_s

		#desc = charge
    bond = 0
    arrest.add_charge(desc, bond)
		
    #end
    scrape.add(arrest)
		scrape.commit()
end
end
}
end
 }
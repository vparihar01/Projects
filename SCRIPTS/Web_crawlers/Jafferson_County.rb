require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Alabama"
COUNTY = "Jafferson County"
CITY = "Alabama"

BASE = "http://www.jeffcosheriff.net/most_wanted.php"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)

arrestsTable=doc.css('table')
 row=arrestsTable[5].css('tr')
(0..row.length-2).each{|r| 
 data=row[r].css('td')

(0..data.length-1).each{|d|
  datas=data[d].css('a')[0]['href'].split('?')[1]
   name=data[d].css('a')[0].text
	 image=data[d].css('a')[0].css('img')[0]['src']
sub_url="#{BASE}?#{datas}"
    doc1 = Nokogiri::HTML(open(sub_url))
		descs=doc1.css('table')
		 descs.length
		  charge=descs[8].css('tr')[9].css('td').css('font').text.strip.split('Charges:')[1].to_s

    arrest = DFG::Arrest.new()
		
		#~ #image
		 arrest.image1 = image

    #~ #name
    arrest.name = name
    
     #date
		arrest.date = Date.today.to_s

		desc = charge
    bond = 0
    arrest.add_charge(desc, bond)
		
    #end
    scrape.add(arrest)
 }

scrape.commit()
}
		#~ }

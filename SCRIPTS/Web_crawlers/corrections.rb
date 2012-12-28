require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Louisiana State"
COUNTY = "Louisiana"
CITY = "Louisiana"

BASE = "http://www.corrections.state.la.us/fugitives"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)


 arrestsTable =doc.css('table#offenders-list')
	arrest = arrestsTable.css('tbody')
	arrestRows=arrest.css('tr')
  arrestRows.length
 (0..arrestRows.size-1).each { |i|
   row = arrestRows[i]
   name1= row.css('td')[0].css('a')[0]['href']

    arrest = DFG::Arrest.new()
		sub_url="http://www.corrections.state.la.us#{name1}"
    doc1 = Nokogiri::HTML(open(sub_url))
		
		#image
		image =doc1.css('.fugleft').css('img')[0]['src']
		 arrest.image1 = image

    #name
		  name= row.css('td')[0].text.split(' ')
  arrest.name = name[0].to_s + ', ' + name[1].to_s
    
     #~ #date
     date = row.css('td')[1].text.strip.to_s.gsub('-','/')
	  arrest.date = DateTime.strptime(date, "%m/%d/%Y")
		
    #state
		#~ state=row.css('td')[2].text.strip
		#~ arrest.state=state
    #charges
     desc = ""
    bond = 0
    arrest.add_charge(desc, bond)
    
    scrape.add(arrest)
 }

scrape.commit()

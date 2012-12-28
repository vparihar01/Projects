require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "MS"
COUNTY = "Hinds County"
CITY = "MS"

BASE = "http://www.co.hinds.ms.us/pgs/apps/inmate/inmate_detail.asp?ID=37343"
DETAIL = "http://www.adasheriff.org/ArrestsReport/wfrmDetail.aspx"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)


	arrestsTable =doc.css('table.tablstyle')
	date= arrestsTable[3].css('tr')[1].css('td')[1].text.slice(4,10)
  charges=arrestsTable[4].css('td').inner_html.split('<br>')[1].to_s
  image=arrestsTable[12].css('td').css('img')[0]['src']
	arrestRows=arrestsTable.css('tr')[1]
  name=arrestRows.css('td')[0].text.strip.split(' ')

    arrest = DFG::Arrest.new()

    #~ #image
		 arrest.image1 = image

    #~ #name
  arrest.name = name[0].to_s + ', ' + name[1].to_s
    
     #date
	  arrest.date = DateTime.strptime(date, "%m/%d/%Y")
    
    #~ #charges
     desc = charges
    bond = 0
    arrest.add_charge(desc, bond)
    
    scrape.add(arrest)
 

scrape.commit()

require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "virgina"
COUNTY = "richmond County"
CITY = "virgina"

BASE = "http://www.centralvirginiamostwanted.com/"
DETAIL = "http://www.adasheriff.org/ArrestsReport/wfrmDetail.aspx"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)


 arrestsTable =doc.css('table')
row=arrestsTable.css('tr')
image1=row[3].css('td').css('img')[0]['src']
name1 = doc.xpath("//div/div[2]/div[8]/div/table/tbody/tr[3]/td/p/span[2]/span/span/span/strong/font").text.split(" ")
arrest1 = DFG::Arrest.new()
    arrest1.image1 = "http://www.centralvirginiamostwanted.com/#{image1}"
   arrest1.name = name1[0].to_s + ', ' + name1[1].to_s
    arrest1.date = Date.today.to_s
     scrape.add(arrest1)
    scrape.commit()

 arrestRows = arrestsTable[2].css('tr')
  p arrestRows.length
 (1..arrestRows.size-1).each { |i|
   row = arrestRows[i]
   image = row.css('td')[0].css('img')[0]['src']
   name=row.css('td')[0].css('p').text
  
   arrest = DFG::Arrest.new()
   arrest.image1 = "http://www.centralvirginiamostwanted.com/#{image}"
   arrest.name = name[0].to_s + ', ' + name[1].to_s
    arrest.date = Date.today.to_s
     scrape.add(arrest)
  scrape.commit()
#~ if image.size > 0  
  }

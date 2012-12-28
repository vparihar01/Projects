require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Idaho"
COUNTY = "GEORGIA"
CITY = "Columbus"

BASE = "http://ccga1.columbusga.org/MCSOFugitive.nsf/Web?OpenPage"
DETAIL = "http://www.adasheriff.org/ArrestsReport/wfrmDetail.aspx"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)


 arrestsTable =doc.css('table')[4]
  arrestRows = arrestsTable.css('tr')
  arrestRows.length
 (0..arrestRows.size-1).each { |i|
   row = arrestRows[i]
   image = row.css('td')[0].css('img')
   image  
  #~ if image.size > 0  
    arrest = DFG::Arrest.new()
    
    #~ #image
    
    image1 =image[1]['src']#.gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    #~ if image1!="pna.gif"
        #~ p arrest.image1 = "/MCSOFugitive.nsf/#{image1}"
        #~ else
         p arrest.image1 = image1
       #~ end
    #name
     name = row.css('td')[1].css('font')[2].text.split(':')[1].split('D.')[0].split(' ')
  arrest.name = name[0].to_s + ', ' + name[1].to_s
    
     #date
    date = Date.today.to_s
    arrest.date = date
    
    #~ #charges
     desc = "#{row.css('td')[1].css('font')[1].text.strip} : #{(row.css('td')[1].css('font')[2].text.split(':')[5].nil? ? "" : row.css('td')[1].css('font')[2].text.split(':')[5])}"
    bond = 0
    arrest.add_charge(desc, bond)
    
    scrape.add(arrest)
  #~ end
 }

scrape.commit()

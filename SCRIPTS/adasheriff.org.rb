#!/opt/local/bin/ruby
require File.join(File.dirname(__FILE__), "scrape.rb")
puts (File.join(File.dirname(__FILE__), "scrape.rb"))
STATE = "Idaho"
COUNTY = "Ada County"
CITY = "Boise"

BASE = "http://www.adasheriff.org/ArrestsReport/wfrmArrestMain.aspx"
DETAIL = "http://www.adasheriff.org/ArrestsReport/wfrmDetail.aspx"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)
post_args = {
  '__VIEWSTATE' => doc.css('input#__VIEWSTATE')[0]['value'],
  '__EVENTVALIDATION' => doc.css('input#__EVENTVALIDATION')[0]['value'],
  'btnDayFive' => doc.css('input#btnDayFive')[0]['value']
}
doc = scrape.post(BASE, post_args)

post_args = {
  '__VIEWSTATE' => doc.css('input#__VIEWSTATE')[0]['value'],
  '__EVENTVALIDATION' => doc.css('input#__EVENTVALIDATION')[0]['value'],
  '__EVENTARGUMENT' => '',
  '__EVENTTARGET' => 'btnShowAll'
}
doc = scrape.post(DETAIL, post_args)

arrestsTable = doc.css('table#dgArrests')
arrestRows = arrestsTable.css('tr')
(1..arrestRows.size-1).each { |i|
  row = arrestRows[i]  
  image = row.css('td')[0].css('img')  
  if image.size > 0  
    arrest = DFG::Arrest.new()
    
    #image
    arrest.image1 = arrest.image2 = image[0]['src'].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    
    #name
    name = row.css('td')[1].css('a')[0].inner_html.split('<br>')[0].split(' ')
    arrest.name = name[0] + ', ' + name[1]
    
    #date
    date = row.css('td')[4].inner_html.split('<br>')[0].strip + '/' + DateTime.now.strftime("%Y")
    arrest.date = DateTime.strptime(date, "%m/%d/%Y")
    
    #charges
    desc = row.css('td')[7].text.strip
    bond = 0
    arrest.add_charge(desc, bond)
    
    scrape.add(arrest)
  end
}

scrape.commit()

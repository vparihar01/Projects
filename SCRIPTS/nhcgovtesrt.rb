require File.join(File.dirname(__FILE__), "scrape.rb")
require 'mechanize'
require 'watir-webdriver'

STATE = "New Hanover"
COUNTY = "New Hanover County Sherriff's Office"
CITY= "Hanover"
		#@agent=Mechanize.new
		BASE="http://p2c.nhcgov.com/p2c/jailinmates.aspx"
		DETAIL="http://p2c.nhcgov.com/p2c/jailinmates.aspx"
	
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
docu = scrape.get(BASE)
next_link=docu.css('tr td')[56].css('a')[0]['href'].split("'")[1]
count=8
loop do
for i in 0..count
post_args = {
  '__VIEWSTATE' => docu.css('input#__VIEWSTATE')[0]['value'],
   '__EVENTVALIDATION' => docu.css('input#__EVENTVALIDATION')[0]['value'],
   
   '__EVENTARGUMENT' => ''
}

 doc = scrape.post(DETAIL, post_args)
 
(12..doc.css('tr td')[6].css('tr td').size-2).step(4).each do |l| 
 link=doc.css('tr td')[6].css('tr td')[l].css('a').map { |u|   u['href']}   
post_args = {
  '__VIEWSTATE' => doc.css('input#__VIEWSTATE')[0]['value'],
   '__EVENTVALIDATION' => doc.css('input#__EVENTVALIDATION')[0]['value'],
   '__EVENTARGUMENT' => '',
  '__EVENTTARGET' => "#{link[0].split("'")[1]}"
}
  dom = scrape.post(DETAIL, post_args)
 extract_url=dom.css('h2 a')[0]['href'].gsub('%2fp2c%2f',"").gsub('%3f','?').gsub('%3d','=')
BASE="http://p2c.nhcgov.com/p2c/#{extract_url}"
  dco = scrape.get(BASE)
puts name=dco.css('tr td p span#ctl00_ctl00_mainContent_CenterColumnContent_lblName.ShadowBoxFont').inner_html
puts charges=dco.xpath('//*[(@id = "ctl00_ctl00_mainContent_CenterColumnContent_dgMainResults")]//tr[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]')[0].inner_html
 data=dco.xpath('//*[(@id = "ctl00_ctl00_mainContent_CenterColumnContent_lblArrestDate")]').inner_html
 a=data.split("/")
date=Date.parse("#{a[1]}/#{a[0]}/#{a[2]}")
 bond=dco.xpath('//*[(@id = "ctl00_ctl00_mainContent_CenterColumnContent_lblTotalBoundAmount")]').css('span').inner_html
image= "http://p2c.nhcgov.com/p2c/Mug.aspx"

  if image.size > 0  
   arrest = DFG::Arrest.new()
    
     #image
     arrest.image1 = arrest.image2 = image.gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    
     #name
  name = name.split('<br>')[0].split(' ')
    arrest.name = name[0] + ' ' + name[1]
    
     #date
   
    arrest.date = date
    
   #charges
   desc = charges
arrest.add_charge(desc, bond)
    
scrape.add(arrest)
scrape.commit()
end


end

puts "*************************#{i}******************************#{i}*****************88"
post_args = {
    '__VIEWSTATE' => docu.css('input#__VIEWSTATE')[0]['value'],
   '__EVENTVALIDATION' => docu.css('input#__EVENTVALIDATION')[0]['value'],
  '__EVENTARGUMENT' => '',
   '__EVENTTARGET' => "#{next_link}"
 }
 docu = scrape.post(DETAIL, post_args)
 puts next_link=docu.css('tr td')[56].css('a')
  puts next_link=docu.css('tr td')[56].css('a').size
puts  next_link=docu.css('tr td')[56].css('a')[i+1]['href'].split("'")[1] rescue ''
break if (docu.css('tr td')[56].css('a')[i+1]['href'].split("'")[1]== nil || docu.css('tr td')[56].css('a')[i+1]['href'].split("'")[1].empty?)
end
count = 9
break if (docu.css('tr td')[56].css('a')[i+1]['href'].split("'")[1]== nil || docu.css('tr td')[56].css('a')[i+1]['href'].split("'")[1].empty?)
end





























require File.join(File.dirname(__FILE__), "scrape.rb")
require 'rubygems'
require 'mechanize'
require 'logger'

STATE = "South Carolina"
COUNTY = "Richland County"
CITY = "Richland County"

BASE = "https://jail.richlandonline.com/public/default.aspx"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
agent = Mechanize.new


page = agent.get('https://jail.richlandonline.com/public/default.aspx')

form = page.form("aspnetForm")

form1=form.click_button
i=1
 agent1= Mechanize.new
loop do
 hiddens=form1.form.form_node
view_state_encrypt=hiddens.css('input#__VIEWSTATEENCRYPTED')[0]['value']
validation=hiddens.css('input#__EVENTVALIDATION')[0]['value']
offender=hiddens.css('input#ctl00_cphMain_hOffenderID')[0]['value']
view_state=hiddens.css('input#__VIEWSTATE')[0]['value']
 forms=form1.form.form_node.css('table')
 row= forms[3].css('tr')
 
 (1..row.length-3).each {|r|
 arrest = DFG::Arrest.new()
name=row[r].css('td')[1].text
 date=row[r].css('td')[5].text

link=form1.form.page.link_with(:text=>"Select")#.each do |link|

page2 = agent1.post('https://jail.richlandonline.com/public/default.aspx',[['__VIEWSTATEENCRYPTED',view_state_encrypt],['__EVENTTARGET', 'ctl00$cphMain$gvMain'],['__EVENTARGUMENT', "Select$#{r-1}"],['__VIEWSTATE',view_state],['__EVENTVALIDATION', validation],['ctl00$cphMain$hOffenderID', offender]]) rescue ""
 view_state_encrypt1=page2.form.form_node.css('input#__VIEWSTATEENCRYPTED')[0]['value']
 validation1=page2.form.form_node.css('input#__EVENTVALIDATION')[0]['value']
offender1=page2.form.form_node.css('input#ctl00_cphMain_hOffenderID')[0]['value']
 view_state1=page2.form.form_node.css('input#__VIEWSTATE')[0]['value']
 img_x=page2.form.buttons.first.x=1
 img_y=page2.form.buttons.first.y=1
 
page3 = agent1.post('https://jail.richlandonline.com/public/default.aspx',[['ctl00$cphMain$imgOffender.y',img_x],['ctl00$cphMain$imgOffender.x',img_y],['__VIEWSTATEENCRYPTED',view_state_encrypt1],['__EVENTTARGET', ''],['__EVENTARGUMENT', ""],['__VIEWSTATE',view_state1],['__EVENTVALIDATION', validation1],['ctl00$cphMain$hOffenderID', offender1]]) rescue ""
 charge1=page3.form.form_node.css('table#ctl00_cphMain_gvCharges')
c_row=charge1.css('tr')

(1..c_row.length-1).each {|cr|
         bond=0
	 desc=""
	 bond=c_row[cr].css('td')[1].text.to_i
	 desc=c_row[cr].css('td')[4].text
	 arrest.add_charge(desc, bond)
}
	 
image1=page2.form.buttons.first.node
 image= image1['src'].gsub('../','/')
 
 arrest.image1 = arrest.image2 = "https://jail.richlandonline.com#{image}" rescue ""
 
 arrest.name = name
 
 arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""

    
     scrape.add(arrest)
     scrape.commit()
}
next_pages=row[row.length-2].css('td')
next_page=next_pages[next_pages.length-1].text rescue ""
last_page=next_pages[next_pages.length-1].text rescue ""
if(next_page=="..." )
  i=i+1
  form1 = agent1.post('https://jail.richlandonline.com/public/default.aspx',[['__VIEWSTATEENCRYPTED',view_state_encrypt],['__EVENTTARGET', 'ctl00$cphMain$gvMain'],['__EVENTARGUMENT', "Page$#{i}"],['__VIEWSTATE',view_state],['__EVENTVALIDATION', validation],['ctl00$cphMain$hOffenderID', offender]]) rescue ""
elsif i==last_page.to_i

 break 
else
	i=i+1
	form1 = agent1.post('https://jail.richlandonline.com/public/default.aspx',[['__VIEWSTATEENCRYPTED',view_state_encrypt],['__EVENTTARGET', 'ctl00$cphMain$gvMain'],['__EVENTARGUMENT', "Page$#{i}"],['__VIEWSTATE',view_state],['__EVENTVALIDATION', validation],['ctl00$cphMain$hOffenderID', offender]]) rescue ""
end

end

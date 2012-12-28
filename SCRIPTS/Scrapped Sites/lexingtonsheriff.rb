require File.join(File.dirname(__FILE__), "scrape.rb")
require 'mechanize'
require 'logger'
STATE = "Idaho"
COUNTY = "Lexington County"
CITY = "South Carolina"

BASE = "http://jail.lexingtonsheriff.net/p2c/jailinmates.aspx"
DETAIL = "http://jail.lexingtonsheriff.net/p2c/InmateDetail.aspx?"
BASE1="http://jail.lexingtonsheriff.net/p2c/jqHandler.ashx?op=s"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)


agent=Mechanize.new
#~ agent.user_agent = 'Individueller User-Agent'
#~ agent.user_agent_alias = 'Linux Mozilla'
#~ agent.open_timeout = 3
#~ agent.read_timeout = 4
#~ agent.keep_alive = true

 agent.methods
 post_args = {
't' =>	"ii"
}
doc = scrape.get(BASE)


validation=doc.css('input#__EVENTVALIDATION')[0]['value']
#~ p offender=doc.css('input#ctl00_ctl00_mainContent_CenterColumnContent_dgMainResults')[0]['value']=1
view_state=doc.css('input#__VIEWSTATE')[0]['value']

p_args=[['_popupBlockerExists','false'],['__EVENTVALIDATION',validation],['__VIEWSTATE',view_state],['ctl00$ctl00$DDLSiteMap1$ddlQuickLinks',0],['__EVENTARGUMENT',''],['__EVENTTARGET',''],['__LASTFOCUS',''],['ctl00_ctl00_mainContent_CenterColumnContent_btnInmateDetail',''],['ctl00_ctl00_mainContent_CenterColumnContent_hfRecordIndex',5]]
 log=Logger.new("test.log")
logg=Logger.new(STDOUT)
p logg.methods
page1=agent.post('http://jail.lexingtonsheriff.net/p2c/jailinmates.aspx',p_args)
 p page1.response.to_hash
#location = URI.parse(page1.response.to_hash["location"].to_a.first)
#~ p page1.form.buttons.first.send(page1.form)

#~ ctl00$ctl00$mainContent$CenterColumnContent$btnInmateDetail
 #~ page1.form.form_node.css('table')[2].css('tr').text
page = agent.get('http://jail.lexingtonsheriff.net/p2c/InmateDetail.aspx?navid=634691229950002500')
 table=page.form.form_node.css('table')
 image="http://jail.lexingtonsheriff.net/p2c/#{table[2].css('tr').css('td')[1].css('img')[0]['src']}"
  doc = Nokogiri::HTML.parse(page.body)
#p page.form.hidden_field#form_node.to_html
#~ form = page.form("aspnetForm")
#~ p form1=form.click_button



#~ form = page.form("aspnetForm")

#~ form.add_field!('__EVENTVALIDATION',validation)
#~ form.add_field!('ctl00_ctl00_mainContent_CenterColumnContent_dgMainResults',2)
#~ form.add_field!('__VIEWSTATE',view_state)
#~ form.add_field!('ctl00$ctl00$DDLSiteMap1$ddlQuickLinks',0)
#~ p page2=agent.submit(form)





#~ doc = scrape.post(BASE1, post_args)
  #~ total=doc.css('p').children.to_s.gsub('"','').split('total:')[1].split(',')[0].strip rescue ''
 #~ row=doc.css('p').children.to_s.gsub('"','').split('records:')[1].split(',')[0].strip rescue ''
 
#~ post_args1 = {
#~ 't' =>	"ii",
 #~ 'rows'=>total.to_i*row.to_i
#~ }

#~ doc = scrape.post(BASE1, post_args1)
#~ arrestsTable=doc.css('p').children.to_s.gsub('"','') rescue ''
#~ (0..(total.to_i*row.to_i)-1).each{ |l|
  #~ arrestsTable
#~ last_name=arrestsTable.split('disp_name:')[l+1].split(',disp')[0].strip rescue ''

#~ date=arrestsTable.split('disp_arrest_date:')[l+1].split(',')[0].strip rescue ''
  #link=arrestsTable.split('first_name:')[l+1].split(',last_name')[l].strip
 #~ desc1=arrestsTable.split('chrgdesc:')[l+1].split(':')[0].split(',') rescue ''
 #~ (0..desc1.length-2).each{ |a| desc1[a]=desc1[a]+desc1[a+1]} rescue ''
#~ desc=desc1[0]

		


#~ image="http://jail.lexingtonsheriff.net/p2c/images/noMug.jpg"

    #~ arrest = DFG::Arrest.new()
    

		 #~ arrest.image1 = image


    #~ arrest.name = last_name
    
  
		#~ arrest.date = Date.strptime(date,"%m/%d/%Y").to_s rescue ''

  #~ desc = ""
    #~ bond = 0
    #~ arrest.add_charge(desc, bond)
		

    #~ scrape.add(arrest)
    #~ scrape.commit()

#~ }



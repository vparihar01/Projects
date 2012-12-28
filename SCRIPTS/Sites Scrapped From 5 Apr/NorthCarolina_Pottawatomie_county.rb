require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "North Carolina"
COUNTY = "Pottawatomie County"
CITY = "Oklahoma City"
BASE="http://p2c.fcso.us/jailinmates.aspx"
DETAIL = "http://p2c.fcso.us/InmateDetail.aspx?"
BASE1="http://p2c.fcso.us/jqHandler.ashx?op=s"
bond=0
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
basedoc=scrape.get(BASE)
 post_args = {
 't' =>	"ii"
 }
 doc = scrape.post(BASE1, post_args)
 total=doc.css('p').children.to_s.gsub('"','').split('total:')[1].split(',')[0].strip  rescue ''
 row=doc.css('p').children.to_s.gsub('"','').split('records:')[1].split(',')[0].strip rescue ''
totalrecords=total.to_i*row.to_i
post_args1 = {
't' =>	"ii",
 'rows'=>totalrecords
}
doc1 = scrape.post(BASE1, post_args1)
records=doc1.css('p').children.to_s.gsub('"','')
for i in 0..(row.to_i-1)
 name=records.split('disp_name:')[i+1].split('(').first rescue " "
 arrestdate=records.split('disp_name:')[i+1].split('disp_arrest_date:').last.split(',date_arr:').first
 arrestdate=Date.strptime(arrestdate,"%m/%d/%Y").to_s rescue ''
 arrest = DFG::Arrest.new()
 arrest.name = name
post_args2 = {
  '__EVENTTARGET' => basedoc.css('input#__EVENTTARGET')[0]['value'],
  '__EVENTVALIDATION' => basedoc.css('input#__EVENTVALIDATION')[0]['value'],
	'__LASTFOCUS' => basedoc.css('input#__LASTFOCUS')[0]['value'],
	'__VIEWSTATE' => basedoc.css('input#__VIEWSTATE')[0]['value'],
 't' =>	"ii",
 'ctl00$ctl00$DDLSiteMap1$ddlQuickLinks'=>0,
 'ctl00$ctl00$mainContent$CenterColumnContent$hfRecordIndex'=>"#{i}",
 'ctl00$ctl00$mainContent$CenterColumnContent$btnInmateDetail'=>''
}
doc2 = scrape.post(BASE, post_args2)
id= doc2.to_s.split('navid%').last.split('>').first.gsub('3d','').chop!
 url=URI.encode("http://p2c.fcso.us/InmateDetail.aspx?navid=#{id}")
doc5= scrape.get(url)
 p arrest.image1=arrest.image2="http://p2c.fcso.us/Mug.aspx"
bondamt=doc5.css('#ctl00_ctl00_mainContent_CenterColumnContent_lblTotalBoundAmount').inner_html
size=doc5.css('#ctl00_ctl00_mainContent_CenterColumnContent_dgMainResults td:nth-child(1)').size rescue ""
for j in 1..size-1
descr=doc5.css('#ctl00_ctl00_mainContent_CenterColumnContent_dgMainResults td:nth-child(1)')[j].to_s.split('<td>').last.split('</td>').first rescue ""
arrest.add_charge(descr, bondamt)
end
scrape.add(arrest)
scrape.commit()
end

















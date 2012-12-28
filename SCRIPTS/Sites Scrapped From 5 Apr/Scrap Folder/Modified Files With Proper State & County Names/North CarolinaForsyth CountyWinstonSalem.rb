=begin
    North Carolina-Forsyth County-Winston-Salem.rb is a Ruby file/crawler which Scraps the Offender Details from North Carolina	Forsyth County-Winston-Salem
    URL => "http://p2c.fcso.us/jailinmates.aspx"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "North Carolina"
COUNTY = "Forsyth County"
CITY = "Winston-Salem"
BASE="http://p2c.fcso.us/jailinmates.aspx"		# Base URL to get the details 
DETAIL = "http://p2c.fcso.us/InmateDetail.aspx?"	# Detail URL to post the arguments
BASE1="http://p2c.fcso.us/jqHandler.ashx?op=s"	# Base1 URL to get the details 
bond=0
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
basedoc=scrape.get(BASE)
 arrest = DFG::Arrest.new()			  # Initilaizing object of Arrest Class
 post_args = {
 't' =>	"ii"			# posting arguments
 }
 doc = scrape.post(BASE1, post_args)	# Posts The arguments to get the page details
 total=doc.css('p').children.to_s.gsub('"','').split('total:')[1].split(',')[0].strip  rescue ''		# get total records
 row=doc.css('p').children.to_s.gsub('"','').split('records:')[1].split(',')[0].strip rescue ''		# get no of rows available
totalrecords=total.to_i*row.to_i
post_args1 = {
't' =>	"ii",
 'rows'=>totalrecords			# Posts The arguments to get the page details
}
doc1 = scrape.post(BASE1, post_args1)
records=doc1.css('p').children.to_s.gsub('"','')
for i in 0..(row.to_i-1)
 name=records.split('disp_name:')[i+1].split('(').first rescue " "		# get name
 arrestdate=records.split('disp_name:')[i+1].split('disp_arrest_date:').last.split(',date_arr:').first		# get date
 arrest.date=Date.strptime(arrestdate,"%m/%d/%Y").to_s rescue ''

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
 p arrest.image1=arrest.image2="http://p2c.fcso.us/Mug.aspx"							# gets image
bondamt=doc5.css('#ctl00_ctl00_mainContent_CenterColumnContent_lblTotalBoundAmount').inner_html
size=doc5.css('#ctl00_ctl00_mainContent_CenterColumnContent_dgMainResults td:nth-child(1)').size rescue ""
for j in 1..size-1
descr=doc5.css('#ctl00_ctl00_mainContent_CenterColumnContent_dgMainResults td:nth-child(1)')[j].to_s.split('<td>').last.split('</td>').first rescue ""	# gets descr
arrest.add_charge(descr, bondamt)		# inserts charges
end
scrape.add(arrest)	# executes inserted Datas
scrape.commit()	# Commits Executed datas
end

















=begin
    Wilkes Barre-Scranton Luzerne County.rb is a Ruby file/crawler which Scraps the Offender Details from Luzerene County
    URL => "http://www.pameganslaw.state.pa.us/SearchResults.aspx?CountyName=LUZERNE&amp;"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The File Scrape.rb
require "mechanize"								# Mechanize gem used for parsing
STATE = "Wilkes Barre"				# State Is mentioned
COUNTY = "Luzerene County"			# County Is mentioned
CITY = "Scranton"					# City is mentioned
BASE="http://www.pameganslaw.state.pa.us/EntryPage.aspx?returnURL=~/SearchCounty.aspx"		# Base Url 
DETAIL="http://www.pameganslaw.state.pa.us/EntryPage.aspx?returnURL=%7e%2fSearchCounty.aspx"	# Detail Url
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)				# Creating An Object Of Scrape Class
arrest = DFG::Arrest.new()									# Creating Object Of Arrest Class
@agent=Mechanize.new										# Creating an Object Of Mechanize Class
doc=@agent.get(BASE) rescue ""										# Mechanize geeting the url i.e opening the home page
    # Entering The form datas
form=doc.form_with(:action => "EntryPage.aspx?returnURL=%7e%2fSearchCounty.aspx") rescue ""
form["ctl00$SessionTimeout1$Timer"]="300 Minutes remaining."
 form["ctl00$MainContent$btnAccept"]="I accept"
 page=@agent.submit(form,form.buttons.last) rescue ""			# Submitting the form
temp_jar=@agent.cookie_jar							# Taking The cookie
@agent=Mechanize.new
@agent.cookie_jar=temp_jar							# Maintaining the Cookie
page=@agent.get("http://www.pameganslaw.state.pa.us/SearchResults.aspx?CountyName=LUZERNE&amp;") rescue ""
no_of_offenders=page.parser.css("#ctl00_MainContent_lblCount").inner_html.to_i rescue ""			# Counting No of Offenders
p page.parser.css("#ctl00_SessionTimeout1_Timer")[0]["value"] rescue ""
count=no_of_offenders/10 rescue ""
count +=1 unless no_of_offenders%10==0 rescue ""				# Increases by 1 if remainder is there
for i in 1..count									# loops through all pages
	links=[]
next_page = {
	'__EVENTARGUMENT' => '',
	'__EVENTTARGET' => 'ctl00$MainContent$gvOffenderList$ctl01$ddlPageSelector',
	'__EVENTVALIDATION' => page.parser.css("input#__EVENTVALIDATION")[0]["value"],
	'__LASTFOCUS' => '',
	'__VIEWSTATE' => page.parser.css("input#__VIEWSTATE")[0]["value"],
	'__VIEWSTATEENCRYPTED' => '',
	'ctl00$MainContent$ddlPageSize' => '10',												# Post Arguments for getting into next and next pages
	'ctl00$MainContent$ddlSort' =>'-1',
	'ctl00$MainContent$gvOffenderList$ctl01$ddlPageSelector' => i,
	'ctl00$MainContent$gvOffenderList$ctl14$ddlPageSelector' => '1',
	'ctl00$SessionTimeout1$Timer' =>'30 Minutes remaining.'
}

page2=@agent.post("http://www.pameganslaw.state.pa.us/SearchResults.aspx?CountyName=LUZERNE&amp%3b",next_page) rescue ""			# Posting the params
p page2.parser.css("#ctl00_SessionTimeout1_Timer")[0]["value"]
page2.parser.css("tr.normal").each {|i|
links << i["onclick"].split("='").last.split("';").first rescue ""					# Taking the links
}	
page2.parser.css("tr.alternate").each {|i|
links << i["onclick"].split("='").last.split("';").first rescue ""					# Taking the links
}
links.each do |li|
next_link=@agent.get("http://www.pameganslaw.state.pa.us/#{li}") rescue ""			# Opening the pages w.r.t offender ids
p next_link.parser.css("#ctl00_SessionTimeout1_Timer")[0]["value"] rescue ""
 date=next_link.parser.css("#ctl00_MainContent_fvDetail_TableCell7").inner_html rescue ""	# Extracting Date
name=next_link.parser.css("#ctl00_MainContent_fvDetail_tblName").inner_html rescue ""
name=name.sub(" ",",") rescue name												# Extracting names
 img=next_link.parser.css("#ctl00_MainContent_fvDetail_Image2")[0]["src"] rescue ""
post_args2= {
	'__EVENTARGUMENT' => '3',
	'__EVENTTARGET' => 'ctl00$MainContent$menuOffenderDetail',
	'__EVENTVALIDATION' => next_link.parser.css("input#__EVENTVALIDATION")[0]["value"],		# Post _arguments for getting into offender_details
	'__VIEWSTATE' => next_link.parser.css("input#__VIEWSTATE")[0]["value"],	
	'__VIEWSTATEENCRYPTED' => '',
	'ctl00$SessionTimeout1$Timer' =>'30 Minutes remaining.'
	}

desc_link=@agent.post("http://www.pameganslaw.state.pa.us/#{li}",post_args2) rescue ""				# Description is being scrapped here
 desc=desc_link.parser.css("#ctl00_MainContent_fvDetail_TableCell3").inner_html.split("-").last rescue ""

arrest.name=name	# Inserting Name
arrest.image1=URI.encode("http://www.pameganslaw.state.pa.us/#{img}") rescue "" # Inserting Image
arrest.date=DateTime.strptime(date, "%m/%d/%Y") if !date.empty?			# Inserting date
bond=0		# Default Bond Amount
arrest.add_charge(desc,bond)	# Adding Charges and Description
scrape.add(arrest)				# Executing Inserted Datas
scrape.commit()				# Commiting Executed Datas
end
end



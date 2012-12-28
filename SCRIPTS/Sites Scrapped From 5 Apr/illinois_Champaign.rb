require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Illinois"
COUNTY = "Champaign  County"
CITY = "Champaign"

BASE="http://www2.illinois.gov/idoc/Offender/Pages/InmateSearch.aspx"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

DETAILEDURL="http://www.idoc.state.il.us/subsections/search/ISListInmates2.asp"
URL="http://www.idoc.state.il.us/subsections/search/ISinms2.asp"
IMAGEURL="http://www.idoc.state.il.us/subsections/search/pub_showfront.asp?idoc="

for k in "a".."z"

post_args = {
'idoc'=>"#{k}",
'selectlist1'=>'Last',
'submit'=>'Inmate Search'
}

doc = scrape.post(DETAILEDURL, post_args)

doc.css('table').css('option').each {|person|

params=person.to_s.split('</font>').last.split('</option>').first.strip! 
id=params.split('|').first.strip!
post_args1={
'idoc'=>params
}
doc2= scrape.post(URL, post_args1)
arrest = DFG::Arrest.new()
name=doc2.css('table')[5].css('font').inner_html.to_s.split('-').last.strip! rescue ''
arrestdate=doc2.css('table')[11].css('font').inner_html.to_s.split('Admission Date: </b>').last.split('<b>').first rescue ''
arrest.date=Date.strptime(arrestdate,"%m/%d/%Y").to_s rescue ''
arrest.name = name
arrest.image1=IMAGEURL+id
scrape.add(arrest)
scrape.commit()
}

end
=begin
     Illinois	ChampaignCounty.rb is a Ruby file/crawler which Scraps the Offender Details from Illinois	Champaign
    URL => "http://www2.illinois.gov/idoc/Offender/Pages/InmateSearch.aspx"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Illinois"
COUNTY = "Champaign  County"
CITY = "Champaign"
BASE="http://www2.illinois.gov/idoc/Offender/Pages/InmateSearch.aspx" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
DETAILEDURL="http://www.idoc.state.il.us/subsections/search/ISListInmates2.asp" # Detail URL for posting data's
URL="http://www.idoc.state.il.us/subsections/search/ISinms2.asp" 
IMAGEURL="http://www.idoc.state.il.us/subsections/search/pub_showfront.asp?idoc=" # Image URL for Extracting Images
for k in "a".."z"   		# loops through a to z from first name to open the offender details page
post_args = {				# posts Arguments
'idoc'=>"#{k}",			# passing values i.e a,b,c .... z
'selectlist1'=>'Last',
'submit'=>'Inmate Search'
}
doc = scrape.post(DETAILEDURL, post_args)	# Posts The arguments to get the page details
doc.css('table').css('option').each {|person|
params=person.to_s.split('</font>').last.split('</option>').first.strip!  rescue ""  # Gets the params to fetch the id
id=params.split('|').first.strip!
post_args1={
'idoc'=>params		# posts parameters
}
doc2= scrape.post(URL, post_args1)	# Posts The arguments to get the page details
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
name=doc2.css('table')[5].css('font').inner_html.to_s.split('-').last.strip! rescue ''		# gets Name
arrestdate=doc2.css('table')[11].css('font').inner_html.to_s.split('Admission Date: </b>').last.split('<b>').first rescue ''		# scraps date
arrest.date=Date.strptime(arrestdate,"%m/%d/%Y").to_s rescue '' 	# inserts date 
arrest.name = name	# inserts name
arrest.image1=IMAGEURL+id # inserts image
scrape.add(arrest)		# Executes the inserted Records
scrape.commit()		# Commits the Executed Datas
}
end
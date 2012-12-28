=begin
     South Carolina  County-South Carolina.rb is a Ruby file/crawler which Scraps the Offender Details from South Carolina  County
    URL => "https://sword.doc.state.sc.us/scdc-public/"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "South Carolina"
COUNTY = "South Carolina  County"
CITY = "South Carolina"


BASE="https://sword.doc.state.sc.us/scdc-public/"
DETAILEDURL="https://sword.doc.state.sc.us/scdc-public/inmateList.do;jsessionid=96A284526598BDBB8A34835107C86BF1"
DETAILEDURL1="https://sword.doc.state.sc.us/scdc-public/instructions.jsp"
baseurl="https://sword.doc.state.sc.us"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
arrest = DFG::Arrest.new()

for i in "a".."z"
post_args={																																																						#Defining the arguments to be passed
'firstName'=>"#{i}",
'lastName'=>"",
'scdcId'=>"",
'sid'=>""
}

doc = scrape.post(DETAILEDURL, post_args)																														#Passing the arguments and url to be scrapped.

doc.css('td:nth-child(1)').css('td').each {|p|
	id=p.inner_html.gsub(/[\r\n\t]/,"") rescue ''
	DETAILEDURL="https://sword.doc.state.sc.us/scdc-public/inmateDetails.do?id=%20#{id}"            #Getting the url
	doc1=scrape.get(DETAILEDURL)																																																								 #scrapping the url
	image=doc1.css('img').to_s.split('src=').last.split('width').first.gsub('"','').gsub('amp;','') rescue ''
	image2=baseurl+image                                                                                                                                                                                      #Getting the image
	name=doc1.css('td:nth-child(1) tr:nth-child(1) td:nth-child(2)').css('td').inner_html.gsub(/[\r\n\t]/,"").squeeze rescue ''               #Getting the name
	arrestdate=doc1.css('td:nth-child(2) tr:nth-child(3) td:nth-child(2)').css('td').inner_html.gsub(/[\r\n\t]/,"") rescue ''                     #Getting the arrest date
	if (name!="")																																																																																																			#Condition to save the details in DB
		arrest.name=name																																																																																														
		arrest.date=arrestdate
		arrest.image1=image2
		scrape.add(arrest)																																																																																															#adding the arrest to scrape DB
		scrape.commit()																																																																																																	#commit the DB.
	end
	}
end




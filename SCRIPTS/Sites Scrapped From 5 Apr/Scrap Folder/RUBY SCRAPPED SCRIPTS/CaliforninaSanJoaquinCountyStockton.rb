=begin
     California San Joaquin  County-Stockton.rb is a Ruby file/crawler which Scraps the Offender Details from Orange County-Orlando
    URL => "http://www.sjgov.org/sheriff/wic.htm"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")		# joins the file scrape.rb


STATE = "California"
COUNTY = "San Joaquin  County"
CITY = "Stockton"

BASE="http://wic.sjsheriff.org/whosincustody/QueryByLastInitial.aspx"		# Base url for getting page details
DETAILEDURL="http://wic.sjsheriff.org/whosincustody/QueryByLastInitial.aspx"	# detailed url for posting datas
baseurl="http://wic.sjsheriff.org"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)	# initializing Scrape object
basedoc=scrape.get(BASE)	# open the BASE url
arrest = DFG::Arrest.new()

for i in "A".."Z"	# loops through a to z to collect every data's
	post_args = {																																																																																			#Defining the arguments to be passed
			'__EVENTARGUMENT' => basedoc.css('input#__EVENTTARGET')[0]['value'],
			'__EVENTVALIDATION' => basedoc.css('input#__EVENTVALIDATION')[0]['value'],
			'__SCROLLPOSITIONX' => basedoc.css('input#__SCROLLPOSITIONX')[0]['value'],			# post arguments
			'__SCROLLPOSITIONY' => basedoc.css('input#__SCROLLPOSITIONY')[0]['value'],
			'__VIEWSTATE'=> basedoc.css('input#__VIEWSTATE')[0]['value'],
			'ctl00$ContentPlaceHolder1$Gender'=>"rbAll",
			'__EVENTTARGET'=>"ctl00$ContentPlaceHolder1$lb#{i}"
	}

	doc1 = scrape.post(DETAILEDURL, post_args)																																																										#Passing the arguments and url to be scrapped.
	doc1.css('#ctl00_ContentPlaceHolder1_gvBookings td:nth-child(1)').each {|p|
	
			url=p.css('a').to_s.split('href=').last.split('>').first.gsub('"','') rescue ''																																#Getting the url for the detailed search
			BASE1=baseurl+url
			base1doc=scrape.get(BASE1)																																																																				#Scrapping the url
			name=base1doc.css('#ctl00_ContentPlaceHolder1_lblNameData').css('span').inner_html rescue ''                         #Getting the name
			arrestdate=base1doc.css('#ctl00_ContentPlaceHolder1_lblBookingDateTimeData').css('span').inner_html.split('at').first.strip! rescue ""   			#Getting the arrest date
			if (name!="" && arrestdate!="")																																																																																								#Condition to save the name and date in DB
				arrest.name=name																																																																																																			#Storing the name and date in DB
			  arrestdate=Date.strptime(arrestdate,"%m/%d/%Y").to_s rescue '' 
				arrest.date=arrestdate
				bailamt=base1doc.css('#ctl00_ContentPlaceHolder1_lblTotalBailData').css('span').inner_html rescue ''                                                              #Getting the bail amount.
			if (bailamt=="Bail not Allowed")																																																																																								#Condition to save the bail amount in DB
				bailamt=0																																																																																	
			end
			base1doc.css('.cellBottom').css('td').each{|desc|																																																																											#Getting all the descriptions 
			descr=desc.inner_html.to_s.squeeze.strip rescue ''                                                          
			arrest.add_charge(descr, bailamt)					     																																																																								#Adding the charges and bailamount 	in DB																		
			} 
			scrape.add(arrest)						# Executing the inserted Records																																																																																					#adding the arrest to scrape DB						
			scrape.commit()						# Commitint the executed records																																																																																						#commit the DB.
			end
}
end
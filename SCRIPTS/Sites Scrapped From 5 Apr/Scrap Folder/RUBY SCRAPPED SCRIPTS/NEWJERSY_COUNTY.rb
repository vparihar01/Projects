=begin
     New Jersy County-New Jersy_doc_inmate.rb is a Ruby file/crawler which Scraps the Offender Details from New Jersy County-New Jersy
    URL => "https://www6.state.nj.us/DOC_Inmate/inmatefinder?i=I"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "New Jersy"
COUNTY = "New Jersy"
CITY = "New Jersy"
BASE="https://www6.state.nj.us/DOC_Inmate/inmatefinder?i=I"
BASE1="https://www6.state.nj.us/DOC_Inmate/inmatesearch"
SEARCHURL="https://www6.state.nj.us/DOC_Inmate/results"
baseurl="https://www6.state.nj.us"
args=[]
desc=""
descr=""
bond=0
m=0
page_no=0
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
arrest = DFG::Arrest.new()
post_args={
'accept'=>'T',
'inmatesearch'=>'Accept'
}
basedoc = scrape.post(BASE1, post_args)																			#Passing the url and arguments to be scrapped.
optionsize=basedoc.css('.standard_font:nth-child(2) div select').css('option').size
for g in 1..optionsize-1
	args<< basedoc.css('.standard_font:nth-child(2) div select').css('option')[g]['value']
end

for a in "a".."z" 																																						#Iterate through a to z
	for b in 0..(args.size-1)																																#Iterate through arguments
		post_args1={																																							#Initializing the arguments 
			'Age'=>'',
			'AgeTo'=>'',	
			'Aliases'=>'NO',
			'County'=>'ALL',
			'Eye_Color'=>'ALL',
			'First_Name'=>"#{a}",
			'Hair_Color'=>'ALL',
			'Increment'=>'20',
			'Last_Name'=>'',
			'Location'=>"#{args[b]}",
			'Race'=>'ALL',	
			'SBI'=>'',	
			'Sex'=>'ALL',
			'Submit'=>'Submit',
			'bday_from_day'=>'None',
			'bday_from_month'=>'None',
			'bday_from_year'=>'None',
			'bday_to_day'=>'None',
			'bday_to_month'=>'None',
			'bday_to_year'=>'None'
		}
		begin
			if (page_no==0)
				doc = scrape.post(SEARCHURL, post_args1)
				page_size = doc.css('#mainContent td td div').size.to_i                      #Calculating the total page
			else
				doc = scrape.post(NEXTURL, post_args1)                                               #Finding the url for the next page
				NEXTURL=""
			end
			size=doc.css('.standard_font:nth-child(3) a').size                            #Getting the size of the record
			for i in 1..size-1                                                                                       #Iterate through each record
				url=doc.css('.standard_font:nth-child(3) a')[i]['href']
				DETAILEDURL=baseurl+url
				doc1=scrape.get(DETAILEDURL)
				name=doc1.css('#mainContent tr:nth-child(5) :nth-child(2)').css('td').inner_html rescue ""         #Getting the name
				if (name.include?('<div'))
					name=doc1.css('#mainContent tr:nth-child(5) :nth-child(2)').css('td').inner_html.split('<div').first
				end
				id=doc1.css('.standard_font td img')[0]['src'] rescue''                                                                                                  #Getting the image id
				 image=baseurl+id                                                                                                               																										#Getting the image
				arrestdate=doc1.css('tr:nth-child(14) :nth-child(2)').css('td').inner_html
				if (name!="")
					arrest.name=name                                  																																																															#Adding the image,name and arrest date to arrest
					arrest.image1=image
					arrest.date=arrestdate
				end
				desc_size=doc1.css('tr:nth-child(1) tr .standard_font:nth-child(1) div').size
				for j in 1..desc_size-1
					desc=doc1.css('tr:nth-child(1) tr .standard_font:nth-child(1) div')[j].inner_html.gsub(/[:<br>\r\n]/,'').squeeze(" ")          #Getting the descriptions
					descr=desc+','+descr
				end
				arrest.add_charge(descr,bond)
				scrape.add(arrest)                                                          											#Storing the arrest in DB                
				scrape.commit()																																										#Commit the DB
				descr=""
			end
			nextpageurl=doc.css('#mainContent td td div').css('a')[page_no]['href'] rescue ''
			page_no=page_no+1
			NEXTURL=baseurl+nextpageurl
		end while page_no < page_size                                        
		page_no=0
	end
end















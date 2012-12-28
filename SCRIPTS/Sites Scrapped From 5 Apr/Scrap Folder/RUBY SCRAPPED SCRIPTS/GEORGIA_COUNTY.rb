=begin
     Georgia County-Georgia.rb is a Ruby file/crawler which Scraps the Offender Details from Georgia County-Georgia
    URL => "http://www.dcor.state.ga.us/GDC/OffenderQuery/jsp/OffQryForm.jsp"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = " Georgia"
COUNTY = "Georgia County"
CITY = "Georgia"

BASE="http://www.dcor.state.ga.us/GDC/OffenderQuery/jsp/OffQryForm.jsp"
SEARCHURL="http://www.dcor.state.ga.us/GDC/OffenderQuery/jsp/OffQryForm.jsp?Institution="
URL="http://www.dcor.state.ga.us/GDC/OffenderQuery/jsp/OffQryRedirector.jsp"
baseurl="http://www.dcor.state.ga.us/"
bond=0
nextpage=0
currentpage=0
totalpage=0
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
arrest = DFG::Arrest.new()

post_args={
'submit2'=>'I agree - Go to the Offender Query',
'vDisclaimer'=>'True'
}
doc = scrape.post(SEARCHURL, post_args)  
for q in "a".."z"                                #Iterate through a to z
k=0
	post_args1={																	#Defining the arguments to be passed
	'NextPage'=>2,
	'RecordsPerPage'=>18,
	'SearchType'=>'',
	'vAgeHigh'=>'',	
	'vAgeLow'=>'',	
	'vAlias'=>'',	
	'vCounty'=>'',	
	'vCurrentInstitution	'=>'',
	'vDetailFormat'=>'Summary',
	'vEyeColor'	=>'',
	'vFirstName'=>"#{q}",
	'vGender'=>'',	
	'vHairColor'=>'',	
	'vHeightHigh'=>'',
	'vHeightLow	'=>'',
	'vIsCookieEnabled'=>"Y",
	'vLastName'=>'',	
	'vListType'=>"PHOTOS",
	'vMiddleName'=>'',	
	'vOffenderId'=>'',	
	'vOffense'=>'',	
	'vOutput'=>"Detailed",
	'vRace'=>'',	
	'vSMT'=>'',	
	'vScope'=>'',	
	'vSentencedTo'=>'',	
	'vUnoCaseNoRadioButton'=>'none',
	'vWeightHigh'=>'',	
	'vWeightLow'=>''
	}
	begin

		if k==0
			doc1=scrape.post(URL, post_args1)                                                                                                                 #Passing the arguments and url to be scrapped
			currentpage=doc1.css('.oq-nav-btwn').css('span').inner_html.split('Page ').last.split(' of').first.to_i
		else
			doc = scrape.post(SEARCHURL, post_args)              																																						#Passing the arguments and url to be scrapped                                                                                        
			post_args3={
			'Action'=>'>',
			'NextPage'=>7
			}
			doc1=scrape.post(URL, post_args3)  
		end
		size=doc1.css('#offender-data li').size
desc=""
		for i in 5..size-1
			 id=doc1.css('#offender-data li')[i].css('form').css('input')[0]['value'] rescue ''                         
			nextpage=doc1.css('#offender-data li')[i].css('form').css('input')[1]['value'] rescue ''
			post_args2={              																																																						                          				#Defining the arguments to be passed                              
				'NextPage'=>nextpage,
				'btn1'=>"More",
				'vRecNo'=>id
			}
			doc2=scrape.post(URL, post_args2)  
			image1="http://www.dcor.state.ga.us/images/offenders/#{id}.jpg" rescue ''                                               #Getting the image              
			name=doc2.css('h4').inner_html.gsub(/[*\n\r]/,'').strip rescue''
			 doc2.css('div#general-content p').each { |k|
			if (k.to_html.include?("OFFENSE"))
			 offense=k.inner_html.split('</strong>')[1].split('<br>').first.strip!.gsub(/[\d]/,'').gsub('&#','')
			 desc=offense+' ,'+desc
			 end
			}
			if (desc!="")
				arrest.add_charge(desc,bond) 
			end
			if (name!="")
				arrest.image1=image1																																																																								#Stroing the name and image in DB
				arrest.name=name
			end
			scrape.add(arrest)                                                                                                                                                      #Adding the arrest to DB
			scrape.commit()																																																																													#commit the DB.
     desc=""
		end	

		currentpage=doc1.css('.oq-nav-btwn').css('span').inner_html.to_s.split('Page ').last.split(' of').first.to_i														#Getting the current page number
		 totalpage=doc1.css('.oq-nav-btwn').css('span').inner_html.to_s.split('Page ').last.split('of ').last.to_i                                  #Getting the Total page number
		k=k+1
	end while currentpage < totalpage

end






















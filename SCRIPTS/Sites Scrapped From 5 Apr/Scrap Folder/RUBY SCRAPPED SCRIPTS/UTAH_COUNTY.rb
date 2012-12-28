=begin
	UTAH  County-UTAH .rb is a Ruby file/crawler which Scraps the Offender Details from UTAH  County-UTAH 
    URL => "http://corrections.utah.gov/services/offender_search.html"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "UTAH "
COUNTY = "UTAH  County"
CITY = "UTAH"
BASE="http://corrections.utah.gov/services/offender_search.html"
BASE1="http://webapps.corrections.utah.gov/correctionsdynamic//Offender_listajax?firstName=&lastName=a&middleName="
AGREEURL="http://webapps.corrections.utah.gov/correctionsdynamic//Offender_agree"
SEARCHURL="http://webapps.corrections.utah.gov/correctionsdynamic/Offender_list"
DETAILEDURL="http://webapps.corrections.utah.gov/correctionsdynamic/Offender_detail"
IMAGEURL="http://webapps.corrections.utah.gov/correctionsdynamic/"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
arrest = DFG::Arrest.new()
for q in "a".."z"																																																																							#Iterate through a to z
	post_args={																																																																											#Passing arguments for user agreement
		'agree'=>'true'
	}
	doc = scrape.post(BASE1, post_args) 																																									#Passing url and arguments for scrapping																																																						 
	post_args1={                                                                                                                                                    #Passing arguments for user agreement
		'firstName'=>'',
		'lastName'=>"#{q}",                                           																																														#Passing the argument q for lastname           
		'middleName'=>''
	}
	doc1 = scrape.post(SEARCHURL, post_args1) 															 	  															                               																       																										                                                                                        
	doc1.css('tr').each { |p|                       
		id=p.css('td')[0].inner_html                                                                                                                               #Getting the id of each record
		post_args2={
			'offenderNumber'=>"#{id}",																																																														#Passing the id to the post arguments
			'view'=>'tabbed'
		}
		doc2 = scrape.post(DETAILEDURL, post_args2)  																																																	#Passing url and arguments for scrapping
		image=doc2.css('#photos').css('img').to_s.split('src=').last.split('alt').first.gsub('"','') rescue ''
		image1=IMAGEURL+image                                                                                                                                #Getting the image
		name=doc2.css('#stats').to_s.split('Offender Name:').last.split('<br>').first.gsub('</b>','').gsub(/[\r\n\t]/,'').squeeze(" ").split(" ") rescue ''        
		firstname=name[0]
		mname=name[1]
		fname=name[2]
		lastname=[fname,mname].join(' ').squeeze(' ')	
		fullname=[lastname,firstname].join(',').squeeze(' ')	 																																															#Getting the name     
		if (name!="")   
			arrest.image1=image1
			arrest.name=fullname
		end
		scrape.add(arrest)                                                                                                                        #Adding the arrest to DB
		scrape.commit()	 																																																													#Commit the DB.
	}
end
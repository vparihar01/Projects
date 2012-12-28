=begin
     West Virginia West Wirginia County-West Virginia.rb is a Ruby file/crawler which Scraps the Offender Details from West Wirginia County-West Virginia
    URL => "http://www.wvdoc.com/wvdoc/OffenderSearch/tabid/117/Default.aspx"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "West Virginia"
COUNTY = "West Virginia County"
CITY = "West Virginia"
BASE="http://www.wvdoc.com/wvdoc/OffenderSearch/tabid/117/Default.aspx"
imagebaseurl="http://www.wvdoc.com/wvdoc"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
arrest = DFG::Arrest.new()																																																				#Creating a object for the arrest table
desc=""
bond=0																																																																		#No bond amount hence initializing it as 0
descriptions=" "
basedoc=scrape.get(BASE)																																																				#Scrapping the base url
for k in 100..999																																																											#Iterate it through all the possible three digit numbers
	post_args={																																																														#Defining the arguments to be passed 
		'__EVENTTARGET' => basedoc.css('input#__EVENTVALIDATION')[0]['value'],
		'__EVENTARGUMENT' => basedoc.css('input#__EVENTARGUMENT')[0]['value'],
		'dnn$ctr238$OffenderSearch$DOCNumber'=>"#{k}",
		'dnn$ctr238$OffenderSearch$LastName'=>'',
		'dnn$ctr238$OffenderSearch$FirstName'=>'',
		'dnn$ctr238$OffenderSearch$doSearch'=>"Search",
		'ScrollTop'=>'',
		'__dnnVariable'=>'',
		'__VIEWSTATEENCRYPTED'=> basedoc.css('input#__VIEWSTATEENCRYPTED')[0]['value'],
		'__EVENTVALIDATION'=> basedoc.css('input#__EVENTVALIDATION')[0]['value'],
		'__VIEWSTATE'=> basedoc.css('input#__VIEWSTATE')[0]['value']
	}
	doc = scrape.post(BASE, post_args)  
	size=doc.css('#dnn_ctr238_OffenderSearch_OffenderList td:nth-child(1)').size rescue ''
	for i in 0..size-1																																																														#Iterate through 0 to size
		
		post_args1={																																																															#Defining the arguments to be passed 
			'__VIEWSTATEENCRYPTED'=> doc.css('input#__VIEWSTATEENCRYPTED')[0]['value'],
		'__EVENTVALIDATION'=> doc.css('input#__EVENTVALIDATION')[0]['value'],
		'__VIEWSTATE'=> doc.css('input#__VIEWSTATE')[0]['value'],
		'ScrollTop'=>'',
		'__dnnVariable'=>'',
		'dnn$ctr238$OffenderSearch$DOCNumber'=>"#{k}",
		'dnn$ctr238$OffenderSearch$LastName'=>'',
		'dnn$ctr238$OffenderSearch$FirstName'=>'',
		'__EVENTTARGET'=>'dnn$ctr238$OffenderSearch$OffenderList',
		'__EVENTARGUMENT'=>"Select$#{i}"
			}

		doc1 = scrape.post(BASE, post_args1)  																																											#Passing the arguments and url for scrapping
		name=doc1.css('#dnn_ctr238_OffenderSearch_det_FullName').css('span').inner_html.split(" ") rescue ''
		firstname=name[0]																																																											#Getting the firstname
		mname=name[1]
		lname=name[2]
		lastname=[lname,mname].join(' ').squeeze(' ')																																				#Getting the lastname
		fullname=[lastname,firstname].join(',').squeeze(' ')																																	
		image=doc1.css('#dnn_ctr238_OffenderSearch_det_OffenderImage').css('img').to_s.split('src=').last.split('style').first.gsub('"','').split('..').last rescue ''
		image1=imagebaseurl+image
		if (name!="")                                                                                                                              #Stroing the name and image in DB.    
			arrest.image1=image1   
			 arrest.name=fullname
		end
		  doc1.css('#dnn_ctr238_OffenderSearch_detailPanel li').each {|p|                               #Getting the descriptions
			desc=p.inner_html.to_s rescue ''
			descriptions=desc+' ,'+descriptions
		}
	  descriptions=descriptions.gsub('&amp','').chop
		if (descriptions!="")
	  arrest.add_charge(descriptions,bond)  																																												#Storing the descriptions in DB.
		end
		scrape.add(arrest)                                                                                                                        #Adding the arrest to DB
		scrape.commit()	 																																																													#Commit the DB.
		
	  desc=""
	  descriptions=""
		
	end
	
end











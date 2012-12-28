=begin
    Arrizona County-Arrizona.rb is a Ruby file/crawler which Scraps the Offender Details from Arrizona County-Arrizona
    URL => "http://www.azcorrections.gov/inmate_datasearch/Index_Minh.aspx"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Arrizona"
COUNTY = "Arrizona County"
CITY = "Arrizona"

BASE="http://www.azcorrections.gov/inmate_datasearch/Index_Minh.aspx"
baseurl="http://www.azcorrections.gov/inmate_datasearch/"
status=["Active","Inactive"]
Gender=["Male","Female"]
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
arrest = DFG::Arrest.new()
bond=0
basedoc=scrape.get(BASE)
for l in 0..1                                                                                                                    #Iterate through 0 to 1 for the status array
	for m in 0..1                                                                                                                #Iterate through 0 to 1 for the Gender array
		for i in "a".."z"																																																					#Iterate through a to z
			for j in "a".."z"																																																				#Iterate through a to z
				k=0                                                                                                                        #Initializing the variables
				currentpage=0
				totalno=0
				nextpage=0
				post_args = {																																									#Defining the arguments to be passed																																																																					
							'__EVENTVALIDATION' => basedoc.css('input#__EVENTVALIDATION')[0]['value'],
							'__VIEWSTATE'=> basedoc.css('input#__VIEWSTATE')[0]['value'],
							'InmateNameSubmit'=>"GO",
							'ctl00$CentralContent$ActiveStatus'=>status[l],
							'ctl00$CentralContent$FirstInitial'=>'',
							'ctl00$CentralContent$Gender'=>Gender[m],
							'ctl00$CentralContent$InmateNumber'=>'',
							'ctl00$CentralContent$LastName'=>"#{i}#{j}"
					}
				begin
					if k==0
						doc = scrape.post(BASE, post_args)  
						currentpage=doc.css('table:nth-child(13) td:nth-child(2)').inner_html.to_s.split('page ').last.split(' of').first.to_i        #Getting the current page number
					else
						post_args1 = {						                                                             #Defining the arguments to be passed																																																																													
									'__EVENTVALIDATION' => basedoc.css('input#__EVENTVALIDATION')[0]['value'],
									'__VIEWSTATE'=> basedoc.css('input#__VIEWSTATE')[0]['value'],
									'PagerHold'=>currentpage,
									'InmateNameSubmit'=>"	Page #{nextpage} >>",            
									'ctl00$CentralContent$ActiveStatus'=>status[l],
									'ctl00$CentralContent$FirstInitial'=>'',
									'ctl00$CentralContent$Gender'=>Gender[m],
									'ctl00$CentralContent$InmateNumber'=>'',
									'ctl00$CentralContent$LastName'=>"#{i}#{j}"
							}
						doc = scrape.post(BASE, post_args1)                                    #Passing the arguments and url to be scrapped.
					end
					doc.css('#ctl00_CentralContent_GridView1 td:nth-child(2)').each {|p|

						id=p.css('a').inner_html
						url=p.css('a').to_html.to_s.split('href=').last.split('>').first.gsub('"','')
						SEARCHURL=baseurl+url                                                                                                                                                                #Getting the url for the detailed search
						doc1=scrape.get(SEARCHURL)
						 lastname=doc1.css('#ctl00_CentralContent_GridView1 td:nth-child(1)').css('td').inner_html rescue ''                           #Getting the lastname
						 firstname=doc1.css('#ctl00_CentralContent_GridView1 td:nth-child(2)').css('td').inner_html rescue ''													
						middlename=doc1.css('#ctl00_CentralContent_GridView1 td:nth-child(3)').css('td').inner_html.to_s.gsub(/[^\w]/,'').gsub(/\d/,'') rescue ''
						firstname1=[firstname,middlename].join(' ').squeeze(' ')
						fullname=[lastname,firstname1].join(',').squeeze(' ')																																																										#Getting the fullname
						arrest.name=fullname																																																																																			#Stroing the fullname in DB.
						image1="http://www.azcorrections.gov/inmate_datasearch/picture_handler.aspx?img=#{id}&searchtype=SearchInet"         #Getting the image
						arrest.image1=image1																																																																																				#Storing the image in DB.
						doc1.css('#ctl00_CentralContent_Commitment td:nth-child(7)').css('td').inner_html.to_s.split(/[\d]/).join("").split('[]:').each {|descr|
						if (descr!="")
						  arrest.add_charge(descr,bond)                                                                                      																																							#storing the descriptions in DB.
						end
						}
						scrape.add(arrest)																																																																																							#Adding the arrest to DB.
						scrape.commit()                                                                                                                                                                                  #Commit the DB.
						currentpage=doc.css('table:nth-child(13) td:nth-child(2)').inner_html.to_s.split('page ').last.split(' of').first.to_i                 #Getting the cuurent page
						totalno=doc.css('table:nth-child(13) td:nth-child(2)').inner_html.to_s.split('page ').last.split('of ').last.to_i                          #Getting the total page
						nextpage=currentpage+1
						}
						k=k+1
				end while currentpage < totalno
			end
		end
	end
end
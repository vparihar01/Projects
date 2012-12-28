=begin
      Arkansas Washington County-Fayettville.rb is a Ruby file/crawler which Scraps the Offender Details(Image, Date, Name, Description) from Washington County-Fayettville(http://adc.arkansas.gov/inmate_info/search.php)!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")   	# Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Arkansas"
COUNTY = "Washington County"
CITY = "Fayettville"
	BASE="http://adc.arkansas.gov/inmate_info/index.php"                                     # Base URL for Scrapping the datas.
	DETAIL="http://adc.arkansas.gov/inmate_info/search.php"                                 # DEATIL URL for Posting the datas.
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)						  # Initializing an Object of Scrape class.
 arrest = DFG::Arrest.new()						 		 				  # Initializing an Object of Arrest class.
 pg_count=[]											       				  # pg_count var of Array Type is initialized.
 for i in "a".."z"         													   # Loop which runs from a to z to fetch all the datas using first name.
 url="http://adc.arkansas.gov/inmate_info/search.php?firstname=#{i}&sex=b&agetype=1&RUN=0"  # url which is used to get all records.
  document=scrape.get(url)														# Scrapped page is stored in document(Variable)
   records=document.css('b span').inner_html.split(' ')[0].to_i					
 pg_count << (records/50).to_i												# total page count is taken as each page consists of 50 datas so its divided by 50.
  end
 
 init=-1					                                              # initialized a init count to -1										
	for i in "a".."z"								# running a loop from a to z
		init=init+1								# for each loop init is incremented by 1
				
	  for j in 0..pg_count[init]						# runs the loop until the page count is satisfied
	url="http://adc.arkansas.gov/inmate_info/search.php?firstname=#{i}&sex=b&agetype=1&RUN=15"
		document=scrape.get(url)                                               # Opens the web-page.
			document.css('.rowitem_sm:nth-child(3)').each {|p|
				p path= p.css('a').to_html.split('"')[1].gsub('amp;','') rescue ""			# gives the url of offender from where details are to be scrapped.
		Main_Url=URI.encode("http://adc.arkansas.gov/inmate_info/#{path}")			# Encodes the URL
			mainpage=scrape.get(Main_Url)											# Opens the offender page
				image= mainpage.css('#appContent img').to_html.split('"')[1].split('"')[0] rescue ""    #Scraps the IMAGE.
				name=mainpage.css('.details table table table tr:nth-child(2) td:nth-child(3) font').inner_html rescue ""  # Scraps the Name.
				date=mainpage.css('tr:nth-child(10) td:nth-child(3) font').inner_html rescue ""                                                    # Scraps the Date.
				date=date.split(';').last if(date.include?(";")) 															# Filters the date from special symbols
				description= mainpage.css('.details table table td:nth-child(1) td:nth-child(1) font').inner_html.gsub('<br>',' ') rescue "" # Scraps the Description.
				
				arrest.image1 = arrest.image2=image rescue ""  # Gives the image to QuickMagick for processing
				arrest.name = name rescue ""                             # Fetches the name into DB
			if !date.nil? || !date.empty?                                  
				arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""           # Fetches the date into DB if a Valid Date is present.
			end
				bond=0
				descr=description										# Fetches the Description
				arrest.add_charge(descr, bond)    							# Adds Charges into DB.
				scrape.add(arrest)										# Executes The DATABASE.
				scrape.commit()										# Commits the Scrapped Datas.
			}
	end

  end
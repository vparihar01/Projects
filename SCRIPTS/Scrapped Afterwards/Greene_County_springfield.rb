=begin
Greene County Springfield.rb is a Ruby file/crawler which Scraps the Offender Details from Greene County
URL => "http://www.greenecountymo.org/sheriff/sex_offender/list.php"!!!
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    		# Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Spring Field"								# State Name mentioned
COUNTY = "Greene County"							# County name  mentioned
CITY = "Spring Field"								# City name Mentioned
BASE="http://www.greenecountymo.org/sheriff/sex_offender/list.php"  # Base URL to get the details
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		# Initializing object of Scrape Class
arrest = DFG::Arrest.new()							 # Initilaizing object of Arrest Class
for i in "A".."Z"									# Loops through to get datas all datas i.e names starting with a to z
    URL="http://www.greenecountymo.org/sheriff/sex_offender/list.php?search=#{i}"
    doc= scrape.get(URL)								# gets Offender page
     doc.css("td a").each { |link|
       id=link["href"]									# Takes the id	
	Next_Url="http://www.greenecountymo.org/sheriff/sex_offender/#{id}" rescue ""
	page=scrape.get(Next_Url)							# Using the id got it scraps the sub url
	date=page.css(":nth-child(4) tr:nth-child(1) td:nth-child(2)").inner_html rescue ""	# Gets date
	name=page.css(":nth-child(4) tr:nth-child(2) td:nth-child(2)").inner_html	 rescue ""# Gets name
	desc=page.css(".fwhite td:nth-child(1)").inner_html	 rescue ""					# Gets Offences
	img=page.css(".right")[0]["src"]	 rescue ""									# Gets Image Id
	image=URI.encode("http://www.greenecountymo.org/sheriff/sex_offender/#{img}") 	# Encodes the image URL
	arrest.image1 = arrest.image2=image 		# inserts image
	arrest.name = name 				# inserts name
    if !date.empty?
      arrest.date = DateTime.strptime(date, "%m/%d/%Y")  rescue ""	# inserts date
    end
	bond=0
	arrest.add_charge(desc, bond)    	# Adds Offences
	scrape.add(arrest)			# Executes the inserted Records
	scrape.commit()			# Commits the Executed Datas
    }
end


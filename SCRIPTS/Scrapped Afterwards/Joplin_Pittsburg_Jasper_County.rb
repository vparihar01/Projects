=begin
     Joplin-Pittsburg_Jasper_County.rb is a Ruby file/crawler which Scraps the Offender Details from Jasper County
    URL => "http://www.icrimewatch.net/index.php?AgencyID=54502&disc="!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Joplin"
COUNTY = "Jasper County"
CITY = "Pittsburgh"
BASE="http://www.icrimewatch.net/index.php?AgencyID=54502&disc=" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class

for i in "a".."z"
	URL="http://www.icrimewatch.net/results.php?AgencyID=54502&SubmitNameSearch=1&OfndrLast=#{i}&OfndrFirst=&OfndrCity="
	doc=scrape.get(URL)
	count=doc.css('.searchArea:nth-child(2) td:nth-child(1) strong').inner_html.strip!.split(" ")[1].to_i rescue ""
	count=count/30
	rem=count%30
		count=count+1 if rem
	for j in 1..count
		PageUrl="http://www.icrimewatch.net/results.php?AgencyID=54502&SubmitNameSearch=1&OfndrCity=&OfndrLast=#{i}&OfndrFirst=&level=&AllCity=&excludeIncarcerated=0&page=#{j}" # Url for opening the Incarcated Offender's Page
		docs=scrape.get(PageUrl)
		docs.css('table:nth-child(3) td:nth-child(5)').css('a').each {|p|
		Offender_Url=URI.encode("http://www.icrimewatch.net/#{p['href']}") rescue ""
			Offender_page=scrape.get(Offender_Url)
			name=Offender_page.css('td:nth-child(2) .nameTitle').css('span').inner_html.sub(" ",",") rescue ""	# Scrapping Name
			date=Offender_page.css('tr:nth-child(13) td:nth-child(2)').inner_html.strip! rescue ""		# Scrapping Booking Date
			image=Offender_page.css('div.tabbertab').css('tr td img')[8]['src'] rescue ""			# Scrapping Offender Image
			desc=Offender_page.css('tr:nth-child(12) td:nth-child(2)').inner_html.split('<br>').first.strip! rescue ""	# Scraping Offences
			date="" if date==nil
			str=date.include?(' ') rescue ""
			if str
			date=date.scan(/\d{2}\/\d{2}\/\d{4}/)[0] rescue ""   # Regex For Matching date
			end

			 arrest.image1=image		# Inserting Image
			 arrest.name=name			# Inserting Name

			if  !date.nil? && !date.empty?
				arrest.date=DateTime.strptime(date, "%m/%d/%Y") rescue ""			# Inserting Date
			end
			arrest.add_charge(desc,0)		# Inserting Charges
			scrape.add(arrest)				# Executing Inserted Datas
			scrape.commit()				# Commiting Executed Datas
		}
	end
	
	
end





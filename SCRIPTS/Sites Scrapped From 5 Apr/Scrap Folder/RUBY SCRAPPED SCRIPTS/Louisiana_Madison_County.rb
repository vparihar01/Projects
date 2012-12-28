=begin
     Louisiana Madison County.rb is a Ruby file/crawler which Scraps the Offender Details from Louisiana Madison County
    URL => "http://www.icrimewatch.net/index.php?AgencyID=54407"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Louisiana"
COUNTY = "Madison County"
CITY = "Madison"
BASE="http://www.icrimewatch.net/results.php?AgencyID=54407&SubmitNameSearch=1&OfndrLast=&OfndrFirst=&OfndrCity=Madison&AllCity=" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class

doc=scrape.get(BASE)
count=doc.css('.searchArea:nth-child(2) td:nth-child(1) strong').inner_html.strip!.split(" ")[1].to_i rescue ""
	count=count/30
	rem=count%30
	if rem
		count=count+1
	end
	count
	for i in 1..count
		URL="http://www.icrimewatch.net/results.php?AgencyID=54407&SubmitNameSearch=1&OfndrLast=&OfndrFirst=&OfndrCity=Madison&AllCity=&excludeIncarcerated=0&page=#{i}"
		docs=scrape.get(URL)
		docs.css('table:nth-child(3) td:nth-child(5)').css('a').each {|p|
			Offender_Url=URI.encode("http://www.icrimewatch.net/#{p['href']}") rescue "" 
			Offender_page=scrape.get(Offender_Url)
			p name=Offender_page.css('td:nth-child(2) .nameTitle').css('span')[1].inner_html rescue ""
			p date=Offender_page.css('tr:nth-child(13) td:nth-child(2)').inner_html.strip! rescue ""
			p image=Offender_page.css('div.tabbertab').css('tr td img')[8]['src'] rescue ""
			p desc=Offender_page.css('tr:nth-child(12) td:nth-child(2)').inner_html.split('<br>').first.strip! rescue ""
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
	


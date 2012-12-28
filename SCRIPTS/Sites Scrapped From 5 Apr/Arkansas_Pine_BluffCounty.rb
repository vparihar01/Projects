=begin
      Arkansas Washington County-Fayettville.rb is a Ruby file/crawler which Scraps the Offender Details(Image, Date, Name, Description) Pine Bluff County(http://adc.arkansas.gov/inmate_info/search.php)!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")   	# Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Arkansas"
COUNTY = "Pine Bluff County"
CITY = "Pine Bluff"
	BASE="http://adc.arkansas.gov/inmate_info/index.php"                                     # Base URL for Scrapping the datas.
	DETAIL="http://adc.arkansas.gov/inmate_info/search.php"                                 # DEATIL URL for Posting the datas.
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
 arrest = DFG::Arrest.new()
 pg_count=[]
 for i in "a".."z"
 url="http://adc.arkansas.gov/inmate_info/search.php?firstname=#{i}&sex=b&agetype=1&RUN=0"
  document=scrape.get(url)
   records=document.css('b span').inner_html.split(' ')[0].to_i
 pg_count << (records/50).to_i
  end
 
 kk=-1
	for i in "a".."z"
		kk=kk+1
				
	  for j in 0..pg_count[kk]
	url="http://adc.arkansas.gov/inmate_info/search.php?firstname=#{i}&sex=b&agetype=1&RUN=15"
		document=scrape.get(url)
			document.css('.rowitem_sm:nth-child(3)').each {|p|
				p path= p.css('a').to_html.split('"')[1].gsub('amp;','') rescue ""
		Main_Url=URI.encode("http://adc.arkansas.gov/inmate_info/#{path}")
			mainpage=scrape.get(Main_Url)
				image= mainpage.css('#appContent img').to_html.split('"')[1].split('"')[0] rescue ""
				name=mainpage.css('.details table table table tr:nth-child(2) td:nth-child(3) font').inner_html rescue ""
				date=mainpage.css('tr:nth-child(10) td:nth-child(3) font').inner_html rescue ""
				date=date.split(';').last if(date.include?(";")) 
				description= mainpage.css('.details table table td:nth-child(1) td:nth-child(1) font').inner_html.gsub('<br>',' ') rescue ""
				
				arrest.image1 = arrest.image2=image rescue ""
				arrest.name = name rescue ""
				puts date
				puts date.empty?
				puts date.nil?
			if !date.nil? || !date.empty?
				arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""
			end
				bond=0
				descr=description
				arrest.add_charge(descr, bond)    
				scrape.add(arrest)
				scrape.commit()
			}
	end

  end
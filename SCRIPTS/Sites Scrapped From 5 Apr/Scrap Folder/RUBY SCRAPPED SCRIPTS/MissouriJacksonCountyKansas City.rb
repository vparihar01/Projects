=begin
     Missouri	Jackson County-Kansas City.rb is a Ruby file/crawler which Scraps the Offender Details from Jackson County-Kansas City
    URL => "http://www.kansascity.com/2011/11/15/1751615/kansas-city-crime-stoppers-most.html#slide-2"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Missouri"
COUNTY = "Jackson County"
CITY = "Kansas City"
	BASE="http://www.kansascity.com/2011/11/15/1751615/kansas-city-crime-stoppers-most.html#slide-1"	# Base URL to get the details 
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)	 # Initializing object of Scrape Class
	arrest = DFG::Arrest.new()  # Initilaizing object of Arrest Class
	doc = scrape.get(BASE)		# gets Offender page
	image=[]
	name=[]
	desc=[]
	doc.css('#nav_scroll_hold img').each {|i|
	image <<  i['src'] rescue ""
	}
	doc.css('.caption').each {|i| 
	content= i.inner_html.split('<span').first.strip! rescue ""
	 names=content.split(',').first rescue ""
	if names.include?('is ')
		names=content.split('is ').first rescue ""	# gets Name
	end
		 name << names
	 desc << content.split('wanted').last.split('. ').first  rescue "" # scraps description
	}
for i in 0..image.size-1
	arrest.image1 = arrest.image2=image[i] rescue ""	# insersts image
	arrest.name = name[i] rescue ""		# insersts name
	bond=0
	descr="Wanted #{ desc[i]}"	# inserts description
	arrest.add_charge(descr, bond)    # inserts charges
	scrape.add(arrest)	#Executes Inserted Datas
	scrape.commit()	# commits Executed Datas
end
	  


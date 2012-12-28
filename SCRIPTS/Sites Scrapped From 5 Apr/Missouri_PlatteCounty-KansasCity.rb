require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Californina"
COUNTY = "Stanislaus County"
CITY = "Modesto"
	BASE="http://www.kansascity.com/2011/11/15/1751615/kansas-city-crime-stoppers-most.html#slide-1"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
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
		names=content.split('is ').first rescue ""
	end
		 name << names
	 desc << content.split('wanted').last.split('. ').first  rescue ""
	}
for i in 0..image.size-1
	arrest = DFG::Arrest.new() 
	arrest.image1 = arrest.image2=image[i] rescue ""
	arrest.name = name[i] rescue ""
	bond=0
	descr="Wanted #{ desc[i]}"
	arrest.add_charge(descr, bond)    
	scrape.add(arrest)
	scrape.commit()
end
	  


=begin
     Louisiana Lincoln County.rb is a Ruby file/crawler which Scraps the Offender Details from Louisiana Lincoln County
    URL => "http://rustonlincolncrimestoppers.org/wanteds.aspx "!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Louisiana"
COUNTY = "Lincoln County"
CITY = "Lincoln"
BASE="http://rustonlincolncrimestoppers.org/wanteds.aspx?F=&F2=&O=SortOrder,ID%20desc" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
doc=scrape.get(BASE)
image=[] ; name=[] ; bond=[] ; descr=[] ; bond=[]; date=[]	# Arrays Initialized
doc.css('#styles img').each {|p|
image << "http://rustonlincolncrimestoppers.org/#{p['src']}" rescue ""	# Scrapping images
}
doc.css('#styles td tr:nth-child(1) td:nth-child(2)').each {|t|
name <<t.inner_html rescue ""										# Scraping Names
}
doc.css('p b').each {|w|
descr << w.inner_html rescue ""										# Scraping Description
}	
doc.css('.MsoNoSpacing strong').each {|t|
content=t.inner_html
if content.include?("span")
	content=t.css('span').inner_html
end
bond << content.split('$').last.gsub(',','').to_i rescue ""			# Scraping Bond Amount	
}

doc.css('#styles td td center').each {|t|
dt= t.inner_html.split(":").last.gsub('</b>','').strip! rescue ""				# Scraping date
date << Date.parse(dt)
}
for i in 0..name.size-1
	arrest.image1=image[i]									# Inserting Images into DB
	arrest.name=name[i]									# Inserting Names into DB
	arrest.add_charge(descr[i],bond[i])							# Inserting charges into DB
	if !date[i].nil?
		arrest.date=date[i] rescue ""									# Inserting date into DB
	end	
scrape.add(arrest)											# Executing Inserted Datas
scrape.commit()											# Commiting executed Datas
end

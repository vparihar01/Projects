require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Orissa"
DST = "KORAPUT"
CITY = "Jeypore"
BASE="http://google.co.in/"
BASE1="http://www.google.co.in/search?um=1&hl=en&biw=1280&bih=936&tbm=isch&sa=1&q=Maa+Durga&oq=Maa+Durga&aq=f&aqi=g10&aql=&gs_nf=1&gs_l=img.3..0l10.6613.9517.0.9733.9.9.0.4.4.0.233.818.0j4j1.5.0.nK3aqmkHgJM" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE,DST, CITY, BASE)  # Initilaized the Scrape Class
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
doc=scrape.get(BASE1)
p=1
doc.css('.rg_i').each {|m|
p image=URI.encode("#{m['data-src']}")
arrest.image1=image

 arrest.name="MAA DURGA#{p}"
p+=1
scrape.add(arrest)
scrape.commit()
}
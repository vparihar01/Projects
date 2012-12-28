=begin
     Louisiana Terrebonne County.rb is a Ruby file/crawler which Scraps the Offender Details from Louisiana Terrebonne County
    URL => "http://173.12.251.178:8888/"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Louisiana"
COUNTY = "Terrebonne County"
CITY = " Parish"
BASE="http://173.12.251.178:8888/" # Base URL to get the details 
DETAIL="http://173.12.251.178:8888/index.php"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
doc=scrape.get(BASE)
 code= doc.css('img')[2]['src'].split('=').last.to_i rescue ""    # Getting the Captcha Code
post_args={
'code'=>code,
'submit'=>'Submit',						# posting the Captch Code to open the page
'verification'=>code
}

image=[] ; name= [] ; date= []					# Initializing Arrays
document=scrape.post(DETAIL,post_args)
for i in "A".."Z"
	URL="http://173.12.251.178:8888/index.php?nav=list&alpha=#{i}"
	document=scrape.get(URL) 
	document.css('.normal img').each {|o|
	image << "http://173.12.251.178:8888/#{o['src']}" rescue ""		# Scrapping Images
	}
	document.css('.tdnoborder a').each { |q|
	name <<  q.inner_html.split('&').first.strip! rescue ""					# Scrapping Names
	}
	document.css('.normal table:nth-child(1) tr:nth-child(1) td:nth-child(3)').each {|r|
	date <<  r.inner_html.split(': ').last.split(' ').first rescue ""			# Scrapping Date
	}
end
for var in 0..name.size-1
	arrest.image1=image[var]		# Inserting Image
	arrest.name=name[var]			# Inserting Name
	if !date[var].nil? || !date[var].empty?
	arrest.date=DateTime.strptime(date[var], "%m/%d/%Y") rescue ""			# Inserting Date
	end
	arrest.add_charge("NIL",0)		# Inserting Charges
	scrape.add(arrest)				# Executing Inserted Datas
	scrape.commit()				# Commiting Executed Datas
end


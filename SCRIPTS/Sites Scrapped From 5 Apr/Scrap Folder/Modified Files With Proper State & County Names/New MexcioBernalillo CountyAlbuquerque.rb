=begin
     New Mexcio	Bernalillo County-Albuquerque.rb is a Ruby file/crawler which Scraps the Offender Details from New Mexcio-Bernalillo County-Albuquerque
    URL => "http://m.bernco.gov/inmate-info-2778/"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "New Mexico"
COUNTY = "Bernalillo County"
CITY = "Albuquerque City"
	BASE="http://app.bernco.gov/custodylist/ReleaseListInter.aspx?id=ALL"	 # Base URL to get the details 
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)				 # Initializing object of Scrape Class
	doc = scrape.get(BASE)		# gets the Base URl
		arrest = DFG::Arrest.new()		# Initilaizing object of Arrest Class
	links=[]
doc.css('#GridView1 a').each {|p|
links <<  URI.encode("http://app.bernco.gov/custodylist/#{p['href']}")	# extracts the offender links
}
for i in 0..links.size-1
BASE=links[i]
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		# Initializing object of Scrape Class
	dcmt = scrape.get(BASE)			# extracts the offender links
	
	img=dcmt.css('#GridView1_Panel , #ViewOffImage')[1]['src']	# scraps image
	 image=URI.encode("http://app.bernco.gov/custodylist/#{img}")	# scraps original image with full web path
	 name=dcmt.css('#GridView1_Panel , #ViewOffImage')[0].css('span').inner_html.split(/\d/)[8]	# scraps name
	content= dcmt.css('#GridView1_Panel , #ViewOffImage')[0].css('span').inner_html.split(',').first	# scraps the whole content
	   day=content.split('/')[0] rescue ""	
	   month=content.split('/')[1] rescue ""
	   year=content.split('/').last.to_i rescue ""
	  date= "#{day}/#{month}/#{year}"		# gets date
 arrest.image1=image	# inserts	image
	 arrest.name=name	# inserts name
	arrest.date=DateTime.strptime(date, "%m/%d/%Y") rescue "" # inserts date
	scrape.add(arrest)	# Executes the inserted data's
        scrape.commit()	# Commits Executed Datas
	
end

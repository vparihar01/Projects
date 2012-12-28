=begin
     Indiana FTWayneCounty.rb is a Ruby file/crawler which Scraps the Offender Details fromIndiana FTWayneCounty
    URL => "http://doc-apps.in.gov/demo/wanted/Most_Wantedlist_public.asp"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Indiana"
COUNTY = "Ft. Wayne County"
CITY = "Ft. Wayne"
BASE="http://doc-apps.in.gov/demo/wanted/Most_Wantedlist.asp?pageno=1&RecPerPage=ALL"  # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		# Initializing object of Scrape Class
 arrest = DFG::Arrest.new()							 # Initilaizing object of Arrest Class
doc= scrape.get(BASE)								# gets Offender page
 doc.css('td.ewTableRow').each {|i|
 f_name= i.css('tr')[0].css('td')[1].css('div').inner_html	# gets FName
 l_name= i.css('tr')[1].css('td')[1].css('div').inner_html	# gets LName
 name=f_name+', '+l_name
img= i.css('tr')[2].css('td')[1].css('a img').to_html.split('"')[1].split('"').first	rescue "" # Scraps image
  image=URI.encode("http://doc-apps.in.gov/demo/wanted/#{img}") 	# Encodes the image URL
  date= i.css('tr')[14].css('td')[1].css('div').inner_html	# scraps the date
arrest.image1 = arrest.image2=image rescue ""		# inserts image
	arrest.name = name rescue ""				# inserts name
	
	if !date.empty?
	 arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""	# inserts date
	 end
	bond=0
	descr="NIL"
	arrest.add_charge(descr, bond)    	# adds Charges
	scrape.add(arrest)			# Executes the inserted Records
	scrape.commit()			# Commits the Executed Datas

}
 
 

 
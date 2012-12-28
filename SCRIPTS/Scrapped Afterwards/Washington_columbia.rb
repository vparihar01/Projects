=begin
     Washington  Columbia County.rb is a Ruby file/crawler which Scraps the Offender Details from Washington County
    URL => "http://mpdc.dc.gov/mpdc/cwp/view,a,1241,Q,540704,mpdcNav_GID,1523,mpdcNav,%7C,.asp"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Columbia"
COUNTY = "Washington County"
CITY = "Columbia"
BASE="http://sexoffender.dc.gov/getOffenders.aspx?type=list"  # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		# Initializing object of Scrape Class
arrest = DFG::Arrest.new()							 # Initilaizing object of Arrest Class
doc= scrape.get(BASE)								# gets Offender page
 doc.css("td:nth-child(8) , td:nth-child(5), td:nth-child(2)").each { |o| 
   if !o.css("a").empty? && !o.css("img").empty?
    name=o.css("b").inner_html rescue ""					# Scrapping Name
     img=o.css("img")[0]["src"] rescue ""					# Image is Scrapped Here
     image=URI.encode(img)
       details=o.css("a")[0]["href"] rescue ""					# Deatils Url Is Collected Here
     document=scrape.get(details)
     desc=document.css("tr:nth-child(8) td").inner_html.split("</b>").last.split("<a").first rescue ""    # Description/Offences is Scrapped Here
     date=document.css("tr:nth-child(9) p").inner_html
        if !date.empty?
		arr=date.scan(/\d+/)
		date="#{arr[0]}/#{arr[1]}/#{arr[2]}"
		arrest.date = DateTime.strptime(date, "%m/%d/%Y")			# Inserts Date
	end
     arrest.image1 = arrest.image2=image rescue ""		# inserts image
    arrest.name = name rescue ""				# inserts name
    bond=0
   arrest.add_charge(desc, bond)    	# adds Charges
   scrape.add(arrest)			# Executes the inserted Records
   scrape.commit()			# Commits the Executed Datas
  end
}
 
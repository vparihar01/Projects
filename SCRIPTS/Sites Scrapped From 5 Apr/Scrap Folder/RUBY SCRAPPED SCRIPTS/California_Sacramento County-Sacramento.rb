=begin
      California Sacramento County-Sacramento  is a Ruby file/crawler which Scraps the Offender Details from Sacramento County-Sacramento 
    URL => http://www.sacsheriff.com/SheriffsMostWanted/ OR http://www.sacsheriff.com/inmate_information/search_names.cfm !!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")   # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Californina"
COUNTY = "Sacramento County"
CITY = "Sacramento"
BASE = "http://www.sacsheriff.com/SheriffsMostWanted/"   # Base url to scrape the datas.
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)              # Initilaized the Scrape Class
doc = scrape.get(BASE)  								    # Opens the Page and stores it into doc(VARIABLE)
name=[]	#Name Array to store names
descr=[]  #Descr Array to store Descriptions
bonds=[]  #bonds Array to store $ BOND AMOUNTS 
image1=[] #image1 & image 2 Array to store Images
image2=[]
doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "mwListingHeader", " " ))] | //*[(@id = "rptWantedPersons_ctl00_pnlMostWantedHeader")]').each {|i|
name << i.css('span').inner_html                              # Scraps the Name
}
doc.css('.mwListingText').each {|m|
descr << m.inner_html.split('Wanted For:</span>').last.gsub('<br>','')          # Scraps the Description
bond_amt=m.inner_html.split('Bail Amount: </span>').last.split('<br>').first.scan(/\d/).join('')        # Scraps the Bond Amount
amt=0 
if !bond_amt.empty?
	bonds << bond_amt.chop!.chop!.to_i                 # converts the bond amt to integer and pushes into bonds
	else 
		bonds << amt                                  # pushes Zero if bond_amt is Nil.
end
}
doc.xpath('//img[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]').each {|i| 
id=i['name'].to_i
image1 << "http://www.sacsheriff.com/SheriffsMostWanted/Image.aspx?id=#{id}"                       # Scraps the path for Image1
image2 << "http://www.sacsheriff.com/SheriffsMostWanted/Image.aspx?id=#{id+1}" 			# Scraps the path for image2
}

for i in 0..name.size-1                                  # loop to insert datas
arrest = DFG::Arrest.new() 			# Creates an object of Arrest class
    arrest.image1 = image1[i]			# inserts image1 into DB
   arrest.image2 = image2[i]			# inserts image2 into DB
    arrest.name = name[i]				# inserts name into DB
    
   desc = descr[i]
   bond=bonds[i]
    arrest.add_charge(desc, bond)        # Adds charges to Database.
   scrape.add(arrest)				 # Executes the Database.
 scrape.commit()				# commits tha data
end
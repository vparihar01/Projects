=begin
      California_Monterey County Monterey is a Ruby file/crawler which Scraps the Offender Details from Monterey County
    URL => "http://www.co.monterey.ca.us/sheriff/wanted.htm" !!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")   # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Californina"
COUNTY = "Sacramento County"
CITY = "Sacramento"
BASE = "http://www.sacsheriff.com/SheriffsMostWanted/"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
doc = scrape.get(BASE)
name=[]
descr=[]
bonds=[]
image1=[]
image2=[]
doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "mwListingHeader", " " ))] | //*[(@id = "rptWantedPersons_ctl00_pnlMostWantedHeader")]').each {|i|
name << i.css('span').inner_html
}
doc.css('.mwListingText').each {|m|
descr << m.inner_html.split('Wanted For:</span>').last.gsub('<br>','')
bond_amt=m.inner_html.split('Bail Amount: </span>').last.split('<br>').first.scan(/\d/).join('')
amt=0
if !bond_amt.empty?
	bonds << bond_amt.chop!.chop!.to_i
	else 
		bonds << amt
end
}
doc.xpath('//img[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]').each {|i| 
id=i['name'].to_i
image1 << "http://www.sacsheriff.com/SheriffsMostWanted/Image.aspx?id=#{id}"
image2 << "http://www.sacsheriff.com/SheriffsMostWanted/Image.aspx?id=#{id+1}"
}

for i in 0..name.size-1
arrest = DFG::Arrest.new() 
    arrest.image1 = image1[i]
   arrest.image2 = image2[i]
    arrest.name = name[i]
    
   desc = descr[i]
   bond=bonds[i]
    arrest.add_charge(desc, bond)    
   scrape.add(arrest)
 scrape.commit()
end
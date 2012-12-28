require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Californina"
COUNTY = "Monterey County"
CITY = "Monterey"
	BASE="http://www.co.monterey.ca.us/sheriff/wanted.htm"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
	img=[]
	name=[]
	charge=[]
total=[]
	doc.css('#AutoNumber4 tr').each {|i| 
		  i.css('img').each {|u| img << u['src']} 
		  i.css('font').each { |p| total << p.inner_html}
	  }
	(0..total.size-1).step(2).each { |i|
name <<  total[i].split('<br>').first rescue ""
 charge << total[i].split('<br>').last.strip! rescue ""
	}
	  
for i in 0..img.size-1
	arrest = DFG::Arrest.new() 
	arrest.image1 = arrest.image2="http://www.co.monterey.ca.us/sheriff/#{img[i]}" rescue ""
	arrest.name = name[i] rescue ""
	bond=0
	desc=charge[i] rescue ""
	arrest.add_charge(desc, bond)    
scrape.add(arrest)
scrape.commit()
end
	  
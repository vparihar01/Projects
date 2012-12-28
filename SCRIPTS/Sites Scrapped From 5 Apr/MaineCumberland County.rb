require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Cumberland"
COUNTY = "Cumberland County"
CITY = "Cumberland"
BASE = "http://www.cumberlandso.org/Fugitive%20Files/mostwanted.htm"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = Nokogiri::HTML(open(BASE))
size=doc.css('#mainContent').css('td').size
image=[]
name=[]
charges=[]
baseurl="http://www.cumberlandso.org"
for i in 0..size-1
image1=doc.css('#mainContent').css('td')[i].css('img').to_s.split('..').last.split(' alt').first.chop
image_string=baseurl+image1
image<<image_string
name<<doc.css('#mainContent').css('td')[i].css('h5').inner_html.split('<br>').first
charges<<doc.css('#mainContent').css('td')[i].css('h6')[2].inner_html.split(': ').last.split('<br>').first
end
for j in 0..size-1	
 arrest = DFG::Arrest.new()
	arrest.image1=image[j]
	arrest.name=name[j]
	arrest.add_charge(charges[j], 0)
	scrape.add(arrest)
	scrape.commit()
 end



require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Nebraska"
COUNTY = "Clinton County"
CITY = "Plattsburgh"
BASE = 	"http://www.omahasheriff.org"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
doc = Nokogiri::HTML(open(BASE))
baseurl="http://www.omahasheriff.org"
size=doc.css('#mainbody').css('#rightcolumn').css('.moduletable').size

(3..size-1).each{ |l|
  detailedurl=doc.css('.moduletable')[l].css('a').to_s.split('href=').last.split('>').first.reverse.chop.reverse.chop
  DETAILEDURL=baseurl+detailedurl
  doc1 = Nokogiri::HTML(open(DETAILEDURL))
  image1=doc1.css('.moduletable')[1].css('img').to_s.split('src=').last.split('">').first.reverse.chop.reverse
  name=doc1.css('.moduletable')[1].css('p').inner_html.split('Name: ').last.split('<br>').first
  charge=doc1.css('.moduletable')[1].css('p').inner_html.split('Charge: ').last.split('<br>').first
  image=baseurl+image1
  arrest = DFG::Arrest.new()
    arrest.name=name
    arrest.image1=image
    bond=0
    arrest.add_charge(charge, 0)
    scrape.add(arrest)
    scrape.commit()
}
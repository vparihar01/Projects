require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "virgina"
COUNTY = "virgina County"
CITY = "virgina"

BASE = "https://apps.co.lubbock.tx.us/jailrosters/activejail.aspx"
DETAIL = "http://www.adasheriff.org/ArrestsReport/wfrmDetail.aspx"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)


names = []
doc.xpath("//table[@id='gridaj']/tr/td[2]").each do |x|
  names << x.text
  end
names.delete_at(0)

names.each do |x|
  arrest = DFG::Arrest.new()
  arrest.name = x.strip
  arrest.date = Date.today.to_s
  scrape.add(arrest)
  scrape.commit()
end

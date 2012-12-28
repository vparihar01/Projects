#!/opt/local/bin/ruby
require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Idaho"
COUNTY = "Ada County"
CITY = "Boise"

BASE = "http://www.adasheriff.org/ArrestsReport/wfrmArrestMain.aspx"
DETAIL = "http://www.amw.com/fugitives/brief.cfm?id=78818"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = Nokogiri::HTML(open('http://www.amw.com/fugitives/brief.cfm?id=78818'))

arrest = DFG::Arrest.new()
arrest.image1 = arrest.image2 = doc.xpath("//span[@class='m5r']/img/@src").first.content
arrest.name = doc.xpath("//div[@class='yui-u first']/h1").first.content.gsub("\r", "")
temp_date = date = doc.xpath("//ul[@class='m0l m0t']/li[1]").last.content.gsub("\r", "").gsub(" ", "-")
arrest.date = Date.strptime(date, "%B-%d-%Y").to_s

scrape.add(arrest)
scrape.commit()

p a = doc.xpath("//div[@class='m20b']/div[@class='row']/div[@class='column span_4']/a/@href")
data = []
a.each do |x|
  data << x.content
end

data.uniq.each do |ur|
  url = "http://www.amw.com#{ur}"
  doc = Nokogiri::HTML(open(url))

  arrest = DFG::Arrest.new()
  arrest.image1 = arrest.image2 = doc.xpath("//span[@class='m5r']/img/@src").first.content
  arrest.name = doc.xpath("//div[@class='yui-u first']/h1").first.content.gsub("\r", "")
  temp_date = date = doc.xpath("//ul[@class='m0l m0t']/li[1]").last.content.gsub("\r", "").gsub(" ", "-")
  arrest.date = Date.strptime(date, "%B-%d-%Y").to_s

  scrape.add(arrest)
  scrape.commit()
end

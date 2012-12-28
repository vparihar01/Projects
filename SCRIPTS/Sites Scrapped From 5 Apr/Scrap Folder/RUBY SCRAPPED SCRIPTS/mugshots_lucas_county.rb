#!/opt/local/bin/ruby
require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Ohio"
COUNTY = "Lucas-County"
CITY = "Ohio"


scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

docs = Nokogiri::HTML(open('http://www.mugshots.com/US-Counties/Ohio/Lucas-County-OH/'))

links = docs.xpath("//div[@class='gallery-listing']/div[@class='row']/a/@href")
links.each do |x|
  temp_url = "http://www.mugshots.com#{x.text}"
  doc = Nokogiri::HTML(open(temp_url))
  arrest = DFG::Arrest.new()
  arrest.image1 = doc.xpath("//div[@class='full-image']/a/img/@src").text
  arrest.name = doc.xpath("//div[@id='main-content-without-skyscraper']/h2").first.text
  arrest.date = Date.today.to_s
  scrape.add(arrest)
  scrape.commit()
end

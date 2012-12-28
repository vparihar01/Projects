#!/opt/local/bin/ruby
require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Missouri"
COUNTY = "Cape Girardeau"
CITY = "Boise"

BASE = "http://www.adasheriff.org/ArrestsReport/wfrmArrestMain.aspx"
DETAIL = "http://www.amw.com/fugitives/brief.cfm?id=78818"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = Nokogiri::HTML(open('http://www.capecountysheriff.org/wanted.php'))

title = []
doc.css("a.ptitles").each do |x|
  title << x.text
end

image_url = []
doc.xpath("//a[@class='text2']/img/@src").each do |x|
  image_url << "http://www.capecountysheriff.org/#{x.text}"
end
links = []
doc.xpath("//a[@class='text2']/@href").each do |x|
  links << "http://www.capecountysheriff.org/#{x.text}"
end

image_url.delete("http://www.capecountysheriff.org/common/images/arrested.png")
image_url.delete("http://www.capecountysheriff.org/templates/capecountysheriff.org/images/Email.png")
links.delete_at(0)

title.each_with_index do |title,index|
  arrest = DFG::Arrest.new()
  arrest.image1 = image_url[index]
  arrest.name = title
  arrest.date = Date.today.to_s

  link_doc = Nokogiri::HTML(open("#{links[index]}"))
  desc = link_doc.xpath("//span[@class='style2']/p[1]").text
  bond = 0
  arrest.add_charge(desc, bond)
  
  scrape.add(arrest)
  scrape.commit()
end

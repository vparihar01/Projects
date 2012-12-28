#!/opt/local/bin/ruby
require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Pima"
COUNTY = "pima County"
CITY = "PIMA"

BASE = "http://www.adasheriff.org/ArrestsReport/wfrmArrestMain.aspx"
DETAIL = "http://www.amw.com/fugitives/brief.cfm?id=78818"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

page_links = []
(1..5).each do |num|
  url_info = "http://www.pimasheriff.org/index.php?cID=1270&q=&sortBy=0&sortOrder=DESC&ccm_paging_p=#{num}"
  docs = Nokogiri::HTML(open(url_info))
  docs.xpath("//ul[@class='commScroll']/li/span[2]/a/@href").each do |links|
    page_links << "http://www.pimasheriff.org#{links.text}"
  end
end

page_links.each do |links|
  doc = Nokogiri::HTML(open(links))

  arrest = DFG::Arrest.new()
  arrest.name = doc.xpath("//div[@id='main']/h3").text
 puts  arrest.image1 = "http://www.pimasheriff.org#{doc.xpath("//div[@class='boxRightThumb']/a/img/@src").text}"

  tmp_date = doc.xpath("//div[@id='main']/p[@class='small']").text.split("On:").last.split(" ")
  date = "#{tmp_date[0]}-#{tmp_date[1].gsub(",", "")}-#{tmp_date[2].gsub(",", "")}"
  arrest.date = Date.strptime(date, "%B-%d-%Y").to_s
  
  
  desc = doc.xpath("//div[@id='main']/p[3]").text
  bond = 0
  arrest.add_charge(desc, bond)

  scrape.add(arrest)
  scrape.commit()
end

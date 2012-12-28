#!/opt/local/bin/ruby
require File.join(File.dirname(__FILE__), "scrape.rb")

url_list = [ 'http://www.bustedmugshots.com/texas/woodville', "http://www.bustedmugshots.com/ohio/lucas", "http://www.bustedmugshots.com/kentucky/anchorage", "http://www.bustedmugshots.com/alabama/gordon", "http://www.bustedmugshots.com/arkansas/bay"]

begin
  url_list.each do |urll|
    STATE = urll.split("/")[3]
    COUNTY = "Ada County"
    CITY = urll.split("/").last

    BASE = "http://www.adasheriff.org/ArrestsReport/wfrmArrestMain.aspx"
    DETAIL = "http://www.amw.com/fugitives/brief.cfm?id=78818"

    scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

    docs = Nokogiri::HTML(open(urll))

    links = docs.xpath("//ul[@class='perps']/div[@id='injection_point']/li/a[1]/@href")
    links.each do |x|
      doc = Nokogiri::HTML(open(x.text))
      arrest = DFG::Arrest.new()
      arrest.image1 = doc.xpath("//div[@class='profile_picture']/img/@src").text
      arrest.name = doc.xpath("//table[@class='profile_information']/tbody/tr[2]/td[2]").text
      arrest.date = Date.strptime(doc.xpath("//table[@class='profile_information']/tbody/tr[5]/td[2]").text, "%m-%d-%Y").to_s
      desc = doc.xpath("//div[@class='left inmate_information']/table[2]").text
      bond = 0
      arrest.add_charge(desc, bond)

      scrape.add(arrest)
      scrape.commit()
    end
  end
rescue Timeout::Error
  puts "Time out error occured"
end

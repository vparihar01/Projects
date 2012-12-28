require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Texas"
COUNTY = "Ada County"
CITY = "Woodville"

BASE = "http://www.adasheriff.org/ArrestsReport/wfrmArrestMain.aspx"
DETAIL = "http://www.amw.com/fugitives/brief.cfm?id=78818"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

docs = Nokogiri::HTML(open("http://bcps.bradfordsheriff.org/smartweb/Jail.aspx"))

#image_url = docs.xpath("//div[@id='JailInfo']/table/tr/td[1]/img/@src")
#names = docs.xpath("//div[@id='JailInfo']/table/tr/td[2]/table/thead/tr/td")
#dates = docs.xpath("//div[@id='JailInfo']/table/tr/td[2]/table/tbody/tr[3]/td[2]")
#bond_values = docs.xpath("//div[@id='JailInfo']/table/tr/td[2]/table/tbody/tr[5]/td[2]")
charges = docs.xpath("//table[@id='JailViewCharges']/tr/td[@nowrap='nowrap'][3]")
charges.each do |value|
  p value.text
end
#image_url.each_with_index do |value, index|
#  arrest = DFG::Arrest.new()
#  arrest.image1 = "http://bcps.bradfordsheriff.org/smartweb/#{value.text}"
#  arrest.name = names[index].text.gsub("  ","").split("(")[0].gsub("\r\n", "")
#  arrest.date = Date.strptime(dates[index].text.strip.split(" ")[0], "%m/%d/%Y").to_s
#  bond = bond_values[index].text.gsub("$", "")
#  desc = charges[index].text if !charges[index].nil?
# 
#  arrest.add_charge(desc, bond)
#  scrape.add(arrest)
#  scrape.commit()
#end

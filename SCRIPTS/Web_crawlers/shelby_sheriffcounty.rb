require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Idaho"
COUNTY = "Ada County"
CITY = "Boise"

BASE = "http://injail.shelby-sheriff.org/kiosk_recent.php?"
DETAIL = "http://injail.shelby-sheriff.org/kiosk_detail.php?"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)

arrestsTable=doc.css('script')
  sid=arrestsTable[4].text.to_s.split('var sid =')[1].split(';')[0].strip.gsub("'","")
  pages=doc.xpath("//table[@class='tbouter2']/tr[3]/td").text.split('of')[1].to_i

(0..pages-1).each{|p|
sub_url="#{BASE}z=#{sid.reverse}&p=#{p.to_i}&num=&m=&o=d&c="
    doc1 = Nokogiri::HTML(open(sub_url))
arrestsTable=doc.css('script')

  sid1=arrestsTable[4].text.to_s.split('var sid =')[1].split(';')[0].strip.gsub("'","")
  last_name=arrestsTable[4].text.to_s.split('var e_ = [')[1].split(']')[0].strip.gsub('"','').split(',')
  first_name=arrestsTable[4].text.to_s.split('var f_ = [')[1].split(']')[0].strip.gsub('"','').split(',')
  date=arrestsTable[4].text.to_s.split('var d_ = [')[1].split(']')[0].strip.gsub('"','').split(',')
  link=arrestsTable[4].text.to_s.split('var b_ = [')[1].split(']')[0].strip.gsub('"','').split(',')
 
(0..link.length-1).each{ |l|
sub_url1="#{DETAIL}z=#{sid1.reverse}&x=#{link[l].reverse}&d="
 sub_url1
    doc2 = Nokogiri::HTML(open(sub_url1))
     images=doc2.css('table')
		 image=images[2].css('tr').css('td').css('img')[0]['src']

    arrest = DFG::Arrest.new()
		#image
		#~ image =doc1.css('.fugleft').css('img')[0]['src']
		 arrest.image1 = image

    #name
    arrest.name = last_name[l].reverse.to_s + ', ' + first_name[l].reverse.to_s
    
     #~ #date
		arrest.date = date[l].reverse.split(' ')[0]

     desc = ""
    bond = 0
    arrest.add_charge(desc, bond)
		
    #~ end
    scrape.add(arrest)
 #~ }
}
		}
scrape.commit()


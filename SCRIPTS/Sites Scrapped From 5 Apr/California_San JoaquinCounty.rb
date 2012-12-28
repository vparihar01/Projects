=begin
      California_Monterey County Monterey is a Ruby file/crawler which Scraps the Offender Details from Monterey County
    URL => "http://www.co.monterey.ca.us/sheriff/wanted.htm" !!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Californina"
COUNTY = "Monterey County"
CITY = "Salinas"

BASE = "http://www.sjgov.org/sheriff/mostwanted.aspx"
DETAIL = "http://www.sjgov.org/sheriff/mostwanted.aspx"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

docs = scrape.get(BASE)
count=docs.css('tr:nth-child(2) td:nth-child(1) td').size
for i in 00..count-3
post_args = {
  '__VIEWSTATE' => docs.css('input#__VIEWSTATE')[0]['value'],
  '__VIEWSTATEENCRYPTED' => '',
   i.to_s.split("").count==1 ? "ctl00$Contentplaceholder1$DataList1$ctl0"+i.to_s+"$ImageButton1.x" : "ctl00$Contentplaceholder1$DataList1$ctl"+i.to_s+"$ImageButton1.x"=> '2',
  
   i.to_s.split("").count==1 ? "ctl00$Contentplaceholder1$DataList1$ctl0"+i.to_s+"$ImageButton1.y" : "ctl00$Contentplaceholder1$DataList1$ctl"+i.to_s+"$ImageButton1.y"=> '5'
}
  doc = scrape.post(DETAIL, post_args)

img= doc.css('#ctl00_Contentplaceholder1_img_pic').to_html.split('src=').last.split('"')[1].gsub('amp;','')
name= doc.css('#ctl00_Contentplaceholder1_lbl_name').inner_html
desc= doc.css('#ctl00_Contentplaceholder1_lbl_wantedFor').inner_html
arrest = DFG::Arrest.new()
p arrest.image1=URI.encode("http://www.sjgov.org/sheriff/#{img}")
	 arrest.name=name
	arrest.add_charge(desc,0)
	scrape.add(arrest)
        scrape.commit()


end

=begin
      California Monterey County-Salinas is a Ruby file/crawler which Scraps the Offender Details from Monterey County
    URL => "http://www.sjsheriff.org/mostwanted.aspx"  OR ALIAS FOR ---"http://www.sjgov.org/sheriff/mostwanted.aspx"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Californina"
COUNTY = "Monterey County"
CITY = "Salinas"

BASE = "http://www.sjgov.org/sheriff/mostwanted.aspx"    # Base url to scrape the datas.
DETAIL = "http://www.sjgov.org/sheriff/mostwanted.aspx"   # DETAIL url to post the datas.

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)		# Initilaized the Scrape Class

docs = scrape.get(BASE)								 # Opens the Page and stores it into docs(VARIABLE)
count=docs.css('tr:nth-child(2) td:nth-child(1) td').size   # Scrapes the total data count
for i in 00..count-3
post_args = {
  '__VIEWSTATE' => docs.css('input#__VIEWSTATE')[0]['value'],                     # Posting Arguments
  '__VIEWSTATEENCRYPTED' => '',
   i.to_s.split("").count==1 ? "ctl00$Contentplaceholder1$DataList1$ctl0"+i.to_s+"$ImageButton1.x" : "ctl00$Contentplaceholder1$DataList1$ctl"+i.to_s+"$ImageButton1.x"=> '2',     # posting x co-ordinate click value
  
   i.to_s.split("").count==1 ? "ctl00$Contentplaceholder1$DataList1$ctl0"+i.to_s+"$ImageButton1.y" : "ctl00$Contentplaceholder1$DataList1$ctl"+i.to_s+"$ImageButton1.y"=> '5'      # posting y co-ordinate click value
}
  doc = scrape.post(DETAIL, post_args)            # opens the page after posting the data's

img= doc.css('#ctl00_Contentplaceholder1_img_pic').to_html.split('src=').last.split('"')[1].gsub('amp;','')    # scraps the image
name= doc.css('#ctl00_Contentplaceholder1_lbl_name').inner_html      			# scraps the name
desc= doc.css('#ctl00_Contentplaceholder1_lbl_wantedFor').inner_html			# scraps the description
arrest = DFG::Arrest.new()	# creates an object of arrest class
arrest.image1=URI.encode("http://www.sjgov.org/sheriff/#{img}")			# Extracts the image
	 arrest.name=name				# inserts name into DB
	arrest.add_charge(desc,0)		# inserts charges into DB
	scrape.add(arrest)				# Executes the datas inserted in DB
        scrape.commit()				# Commits the executed Data


end

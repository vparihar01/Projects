require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Idaho"
COUNTY = "Lexington County"
CITY = "South Carolina"

BASE = "http://jail.lexingtonsheriff.net/p2c/jailinmates.aspx"
DETAIL = "http://jail.lexingtonsheriff.net/p2c/InmateDetail.aspx?"
BASE1="http://jail.lexingtonsheriff.net/p2c/jqHandler.ashx?op=s"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

 post_args = {
't' =>	"ii"
}
doc = scrape.get(BASE)

doc = scrape.post(BASE1, post_args)
  total=doc.css('p').children.to_s.gsub('"','').split('total:')[1].split(',')[0].strip
 row=doc.css('p').children.to_s.gsub('"','').split('records:')[1].split(',')[0].strip
 
post_args1 = {
't' =>	"ii",
 'rows'=>total.to_i*row.to_i
}

doc = scrape.post(BASE1, post_args1)
 p arrestsTable=doc.css('p').children.to_s.gsub('"','')
(0..(total.to_i*row.to_i)-1).each{ |l|
  arrestsTable
 p last_name=arrestsTable.split('disp_name:')[l+1].split(',disp')[0].strip

 p date=arrestsTable.split('disp_arrest_date:')[l+1].split(',')[0].strip
  #~ link=arrestsTable.split('first_name:')[l+1].split(',last_name')[l].strip
 desc1=arrestsTable.split('chrgdesc:')[l+1].split(':')[0].split(',')
 (0..desc1.length-2).each{ |a| desc1[a]=desc1[a]+desc1[a+1]}
desc=desc1[0]
		 image="http://jail.lexingtonsheriff.net/p2c/images/noMug.jpg"

    arrest = DFG::Arrest.new()
    
		#image
		#~ image =doc1.css('.fugleft').css('img')[0]['src']
		 arrest.image1 = image

    #name
    arrest.name = last_name
    
     #~ #date12/21/2011
		arrest.date = Date.strptime(date,"%m/%d/%Y").to_s

  desc = ""
    bond = 0
    arrest.add_charge(desc, bond)
		
    #~ end
    scrape.add(arrest)
    scrape.commit()
 #~ }
}


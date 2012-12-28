require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Idaho"
COUNTY = "South Carolina"
CITY = "Charleston County"

BASE = "http://www.ccso.charlestoncounty.org/index2.asp?p=/wanted.html"
DETAIL = "http://www.adasheriff.org/ArrestsReport/wfrmDetail.aspx"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)

#~ row= doc.xpath("//table[@id='table64']/tr")
arrestsTable =doc.css('table')

 arrestRows = arrestsTable[14].css('tr')

(0..arrestRows.length-1).each { |i|
if i%2==1 
	row = arrestRows[i]#.css('td').css('img')[0]['src']
	if  i==0
		row1=arrestRows[i].css('td')
		image=row1[0].css('img')[0]['src'].gsub('../','/')
		name=row1[2].inner_html.split('<b>')[1].split('</b>')[0].gsub("\r","").gsub("\n","").gsub("\t","").strip.split(',')
		desc=row1[2].inner_html.split('<i>')[1].split('</i>')[0]

 #p name1=name[1].inner_html
	else
		
		row1=arrestRows[i]
	image=row1.css('img')[0]['src'].gsub('../','/')
	if !row1.inner_html.split('<b>')[1].nil?
		name=row1.inner_html.split('<b>')[1].split('</b>')[0].gsub("\r","").gsub("\n","").gsub("\t","").strip.split(',')
	else
		name=row1.inner_html.split('<strong>')[1].split('</strong>')[0].gsub("\r","").gsub("\n","").gsub("\t","").strip.split(',')
	end
	if !row1.inner_html.split('<i>')[1].nil?
		desc=row1.inner_html.split('<i>')[1].split('</i>')[0].gsub("\r","").gsub("\n","").gsub("\t","").strip
   else
		desc=row1.inner_html.split('<em>')[1].split('</em>')[0].gsub("\r","").gsub("\n","").gsub("\t","").strip
	 end
	 
end

 
    arrest = DFG::Arrest.new()
		
		#image
		  arrest.image1 = image

    #name
		   arrest.name = name[0].to_s + ', ' + name[1].to_s
    
     #~ #date
       date = Date.today.to_s
	     arrest.date = date
		    
    #charges
     #~ desc = ""
    bond = 0
    arrest.add_charge(desc, bond)
    
    scrape.add(arrest)
		#~ end
		end
 }

scrape.commit()

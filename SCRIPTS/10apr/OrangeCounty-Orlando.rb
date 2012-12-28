require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Florida"
COUNTY = "Orange County"
CITY = "Orlando"
BASE="http://apps.ocfl.net/bailbond/Default.asp"
DETAIL ="http://apps.ocfl.net/bailbond/Default.asp"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
 arrest = DFG::Arrest.new()
 for i in "a".."z"
post_args = {
 'SEARCHTEXT'=> "#{i}",
 'Search'=>'Search'
 }
 
 document=scrape.post(BASE, post_args)
 document.css('td.ten').css('a').each { |u|
 p link="http://apps.ocfl.net/#{u['href']}"
 open=scrape.get(link)
 p name=open.css('b font').inner_html rescue ""
  p img=open.css('tr td#content img')[0]['src'] rescue ""
 p image="http://apps.ocfl.net/bailbond/#{img}"
p date=open.css('#Table5 tr:nth-child(7) td:nth-child(2) font').inner_html rescue ""
 p amt=open.css('#Table6 tr:nth-child(3) td:nth-child(2) font').inner_html rescue ""
  p description=open.css('#Table6 tr:nth-child(7) td:nth-child(2) font:nth-child(1)').inner_html rescue ""
if description.include?('<br>')
p description=description.split('<br>').first
end
arrest.image1 = arrest.image2=image rescue ""
	arrest.name = name rescue ""
	if date
	 arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""
	 end
	bond=amt
	descr=description
	arrest.add_charge(descr, bond)    
	scrape.add(arrest)
	scrape.commit()

 }
 end
 

require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "EAST BATON"
COUNTY = "EAST BATON ROUGE OFFICE"
CITY= "EAST BATON"

		BASE="http://www.ebrso.org/Home/tabid/38/MostWanted/tabid/79/Default.aspx"
		scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
		doc = scrape.get(BASE)
img=[]
description = []
date=[]
name=[]
 doc.css('div#dnn_ctr400_HtmlModule_lblContent.Normal p').css('img').each {|image| img << image['src'] }
count=doc.css('div#dnn_ctr400_HtmlModule_lblContent.Normal p').size-2
(2..count).step(2) {|i|
description << doc.css('div#dnn_ctr400_HtmlModule_lblContent.Normal p')[i].text
name << doc.css('div#dnn_ctr400_HtmlModule_lblContent.Normal p')[i].text.split(" ")[0..1]
}
count_date=doc.css('table tbody tr td').size-7
(11..count_date).step(7) {|i|
date << doc.css('table tbody tr td')[i].inner_html
}

 for i in 0..date.size-1
	 arrest = DFG::Arrest.new()
 arrest.image1 = arrest.image2= img[i].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
 arrest.name = name[i].to_s
 a=date[i].split("/")
 arrest.date=Date.parse "#{a[1]}/#{a[0]}/#{a[2]}"
 desc=description[i]
bond = 0
arrest.add_charge(desc, bond)
scrape.add(arrest)
scrape.commit()
end



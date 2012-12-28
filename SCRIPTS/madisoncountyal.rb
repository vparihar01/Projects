require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Madison"
COUNTY = "Madison County"
CITY = "Madison"
BASE="http://sheriff.madisoncountyal.gov/mostwanted.php"
	puts BASE
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
	
	img= []
	doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "pagetext", " " ))]//img').each {|p| img << p['src']}

	puts img.size
	detail =[]
	doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "pagetext", " " ))]//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]').each { |u| detail << u}
	arrest = DFG::Arrest.new()
	for i in 0..img.size-1
		arrest.image1 = image2=img[i].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
		arrest.name = detail[i].inner_html.split('<br>')[0].gsub('<b>Name:</b>','')
		desc = charge=detail[i].inner_html.split('<br>')[14]#.gsub('<b>Name:</b>','')
		
		puts bond = detail[i].inner_html.split('<br>')[14].split('$').last.split(' ').first.scan(/\d+/).join('').to_i rescue ''
		arrest.add_charge(desc, bond)
    
		scrape.add(arrest)
	scrape.commit()
	end

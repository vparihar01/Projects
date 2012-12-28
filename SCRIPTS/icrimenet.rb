require 'mysql'
require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Sheriif's Office"
COUNTY = "VanderBurgh County"
CITY= "EvansVille"
	BASE="http://www.icrimewatch.net/results.php?AgencyID=54882&SubmitNameSearch=1&OfndrLast=&OfndrFirst=&OfndrCity=Evansville&AllCity"
	scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
	doc = scrape.get(BASE)
	count=doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "searchArea", " " )) and (((count(preceding-sibling::*) + 1) = 2) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]//strong').inner_html.split(' ')[1].to_i
	total=count/30
	total=total+1 if total%30 !=0
	next_links=[]
	for i in 1..total
		BASE="http://www.icrimewatch.net/results.php?AgencyID=54882&SubmitNameSearch=1&OfndrCity=Evansville&OfndrLast=&OfndrFirst=&level=&AllCity=&excludeIncarcerated=0&page=#{i}"
		scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
		doc = scrape.get(BASE)
		nextlink=doc.xpath("//td[(((count(preceding-sibling::*) + 1) = 5) and parent::*)]/a").map { |link| next_links << link['href'] if  link['href'].match("OfndrID") }
	end
       next_links.each do |maa|
		BASE="http://www.icrimewatch.net/#{maa}"
		puts BASE
		#BASE="http://www.icrimewatch.net/offenderdetails.php?OfndrID=1266372&AgencyID=54882"
		scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
		doc = scrape.get(BASE)
		image = []
		doc.xpath('//img').map { |link| image << link['src'] if  link['src'].match("grabphoto") }
		if image.size > 0  
    arrest = DFG::Arrest.new()
    arrest.image1 = arrest.image2 = image[0].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
    puts name=doc.css('span.nameTitle')[1].inner_html
    arrest.name = name 
   
     if (!doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "tabbertab", " " ))]//table[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]//tr[(((count(preceding-sibling::*) + 1) = 4) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]').text.empty?) 

    date=doc.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "tabbertab", " " ))]//table[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]//tr[(((count(preceding-sibling::*) + 1) = 4) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]').text.split(' ')[0].lstrip! rescue  ''
	if date
	    arrest.date = date rescue ''
    end
    end

  puts desc=doc.xpath('//tr[(((count(preceding-sibling::*) + 1) = 12) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]').text.strip! if (doc.xpath('//tr[(((count(preceding-sibling::*) + 1) = 12) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]'))
   if desc == nil
	    desc = ""
  end
  bond = 0
   arrest.add_charge(desc, bond)
   scrape.add(arrest)
   
     end
     scrape.commit()
     end




require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "STATE.MS.US"
COUNTY = "Mississippi  Department of  Corrections"
CITY= " CMCF "

		BASE="http://www.mdoc.state.ms.us/InmateDetails.asp?PassedId=141283"
		scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
		doc = scrape.get(BASE)
		image=[]
		puts  doc.xpath('//*[(@id = "table7")]//p[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]//img').map { |link| image << link['src'] if  link['src'].match("GetImageBytes") }
		
		if image.size > 0  
			arrest = DFG::Arrest.new()
			#arrest.image1 = arrest.image2 = image[0].gsub('Thumbnails', 'MugShots').gsub(' ', '%20')
			img=image[0].gsub('\\\\','\\\\\\\\')
			puts encode_url="http://www.mdoc.state.ms.us/#{img}"
			puts URI.encode(encode_url)
			arrest.image1 = arrest.image2 = URI.encode(encode_url)
		       puts name=doc.xpath('//*[(@id = "table4")]//tr[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]//font').text
			arrest.name = name   
			puts date=doc.xpath('//tr[(((count(preceding-sibling::*) + 1) = 12) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]//font').text
			 if (date) 
				 a="#{date}".split("/")
			else
					 a=Date.today
			end
			arrest.date = Date.parse "#{a[1]}/#{a[0]}/#{a[2]}"
			desc=doc.xpath('//tr[(((count(preceding-sibling::*) + 1) = 19) and parent::*)]//font').text
			if desc == nil
				desc = ""
			end
				bond = 0
			arrest.add_charge(desc, bond)
			scrape.add(arrest)
			scrape.commit()
  		#~ end
 end
	

=begin
     Missouri Springfield County-Springfield.rb is a Ruby file/crawler which Scraps the Offender Details from Springfield County-Springfield
    URL => "https://web.mo.gov/doc/offSearchWeb/"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = " Missouri"
COUNTY = "Springfield County"
CITY = "Springfield"

BASE="https://web.mo.gov/doc/offSearchWeb/"
DETAILEDURL="https://web.mo.gov/doc/offSearchWeb/searchOffender.do"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

bond=0
arrest = DFG::Arrest.new()
for i in "a".."z"
 for j in "a".."z"
post_args={                                                                                                                  #Defining the arguments to be passed
'btnAction'=>'Search',
'docId'=>''	,
'firstName'=>"#{i}",
'lastName'=>"#{j}"
}

 doc = scrape.post(DETAILEDURL, post_args)                                                                 #Passing the arguments and url to be scrapped.
 doc.css('table:nth-child(8) td:nth-child(1)').each {|p|
  id=p.css('a').inner_html
  URL=p.css('a').to_s.split('href=').last.split('>').first.split('"').last                            #Getting the url for the detailed search
  
  doc1=scrape.get(URL)                                                                                                                                                                         #Getting the document for the detailed search
  firstname=doc1.css('.displayTable tr:nth-child(2) td:nth-child(2)').css('td').inner_html.split(" ").first rescue ""                                         #Getting the firstname
  lastname=doc1.css('.displayTable tr:nth-child(2) td:nth-child(2)').css('td').inner_html.scan(/^(\w+)[ .,](.+$)/).flatten[1] rescue ""           #Getting the lastname
  name=[lastname,firstname].join(',')                                                                                                                                                                           #Getting the fullname
  arrest.name=name                                                                                                                                                                                                      #Storing the name in DB.
  desc=doc1.css('tr:nth-child(12) td:nth-child(2)').css('td').inner_html.split(';')                                                                                                #Getting the descriptions
  desc_size=doc1.css('tr:nth-child(12) td:nth-child(2)').css('td').inner_html.split(';').size
  for j in 0..desc_size-1
   descr=desc[j]
   arrest.add_charge(descr, bond)                                                                                                                                                                                      #storing the descriptions in DB.
  end
  post_args1={                                                                                                                                                                                                            #Passing the arguments and url to be scrapped
  'btnAction'=>'Photos',
  'docId'=>id
 }
   doc2 = scrape.post(DETAILEDURL, post_args1                                                                                                                                #Passing the arguments and url to be scrapped.                                       
   size=doc2.css('.border').css('img').size

     image1=doc2.css('.border').css('img')[0].to_s.split('src=').last.split('width').first.gsub('"','') rescue ''                   #Getting the image1
     image2=doc2.css('.border').css('img')[1].to_s.split('src=').last.split('width').first.gsub('"','') rescue ''                   #Getting the image2
     if (image1!=""&&image2!="")                                                                                                                                            #Conditions to store the images in DB.
      arrest.image1=image1
      arrest.image2=image2
     end
     scrape.add(arrest)                                                                                                                                                                      #adding the arrest to scrape DB
     scrape.commit()                                                                                                                                                                         #commit the DB.
}
end
end
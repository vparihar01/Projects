require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Montana"
COUNTY = "Billings County"
CITY = "Billings"
BASE="https://app.mt.gov/cgi-bin/conweb/conwebLookup.cgi"
DETAIL ="https://app.mt.gov/cgi-bin/conweb/conwebLookup.cgi"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
 arrest = DFG::Arrest.new()
 for i in "a".."z"
post_args = {
 'Gender'=>'-',
'Search'=>'Search',
'docid'=>'',	
'ethnicity'=>'- Choose One -',
'firstname'=>'',
'lastname'=>"#{i}",
'status'=>'- Choose One -',
'year'=>'Year'
}
document=scrape.post(DETAIL,post_args)
 document.css('.results a').each {|p|
p link= URI.encode("https://app.mt.gov/#{p['href']}")
detail=scrape.get(link)
img=detail.css('.text2 img').to_html.split('"')[1]
arrest.image1=URI.encode("https://app.mt.gov#{img}")
scrape.commit()
p "**************************"
}

end
=begin
     GREENBAY County.rb is a Ruby file/crawler which Scraps the Offender Details from GREENBAY County
    URL => "http://offender.doc.state.wi.us/lop/home.do"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")         # Joins The scrape.rb file which opens a webpage and stores the details into Database

STATE = "Wisconsin"
COUNTY = "GreenBay County"
CITY = "Wisconsin"
BASE="http://offender.doc.state.wi.us/lop/"        # Base URL to get the details 
DETAIL="http://offender.doc.state.wi.us/lop/home.do"     # Detail URL for posting data's
DETAIL1="http://offender.doc.state.wi.us/lop/searchbasic.do"      # Detail1 URL for posting data's
DETAIL2="http://offender.doc.state.wi.us/lop/detail.do"    # Detail2 URL for posting data's
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)                # Initilaized the Scrape Class
bond=0
arrest = DFG::Arrest.new()                             # Initilaizing object of Arrest Class
post_args={
'clientBrowser'=>'not ie',
'type'=>'basic'
}

 doc=scrape.post(DETAIL, post_args)
 for i in "A".."Z"                                                  # loops through A to Z from first name to open the offender details page
 for j in "A".."Z"                                                  # loops through A to Z from last name to open the offender details page
post_args1={
'ADR_CITY'=>'',	
'ADR_COUNTY'=>'',	
'ADR_MAX_ZIP'=>'',	
'ADR_MIN_ZIP'=>'',	
'BIRTH_YEAR'=>'',	
'DOC_NUM'=>'',	
'EXCLUDE_TERMINATED'=>'YES',
'FIRST_NAM'=>"#{i}",
'GENDER'=>'',	
'LAST_NAM'=>"#{j}",
'MAX_AGE'=>'',	
'MID_NAM'=>'',	
'MIN_AGE'=>'',	
'RACE'=>'',	
'helpMenu'=>'/lop/help/PLHelp.htm#Search Tips',
'pageSize'=>'25',
'searchpage'=>'basic',
'sortBy'=>'2',
'view'=>'demographics'
}
 doc1 = scrape.post(DETAIL1, post_args1)
doc1.css('.XPListText:nth-child(1) a').each{ |p|
 id=p.to_s.split('(').last.split(')').first.split("'").last.to_i
 post_args2={
'ADR_CITY'=>'',
'ADR_COUNTY'=>'',	
'ADR_MAX_ZIP'=>'',	
'ADR_MIN_ZIP'=>'',	
'BIRTH_YEAR'=>'',	
'DOC_NUM'=>'',	
'EXCLUDE_TERMINATED'=>'true',
'FIRST_NAM'=>'A',
'GENDER'=>'',	
'LAST_NAM'=>'A',
'MAX_AGE'=>'',	
'MAX_RECORDS'=>'2001',
'MID_NAM'=>'',	
'MIN_AGE'=>'',	
'PM_DESC_SEARCH'=>'SMT_DESCRIPTION_AND',
'RACE'=>'',	
'SMT_DESCRIPTION_AND'=>'true',
'firstRow'=>'1',
'helpMenu'=>'/lop/help/PLHelp.htm#Your Results',
'navigation'=>'5',
'pageSize'=>'25',
'pin'=>"#{id}",
'rowCount'=>'248',
'searchview'=>'null',
'sortBy'=>'2',
'sortOrder'=>'A',
'view'=>'demographics'
}

 doc2=scrape.post(DETAIL2, post_args2)          #Posting Arguments to open Offender Page
 image=doc2.css('.mainTD a img').css('img')[0]['src']
  img="http://offender.doc.state.wi.us"+image               # Scraps Image
  name=doc2.css('td:nth-child(3) tr:nth-child(1) .XPBody .FormTextData').css('span').inner_html              # Scraps Name

  date=doc2.css('tr:nth-child(3) .XPBody .FormTextData').css('span').inner_html.gsub(/[\r\n\t]/,' ').strip!      # Scraps Date
  if !date.empty?
	 arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""      # Inserts date
	 end
 arrest.image1 = arrest.image2=img rescue ""      # Inserts image
arrest.name = name                # Inserts name
arrest.add_charge(NIL,0)
scrape.add(arrest)
scrape.commit()


}
end
end


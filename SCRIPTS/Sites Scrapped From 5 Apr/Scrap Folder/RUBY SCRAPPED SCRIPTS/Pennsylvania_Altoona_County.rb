=begin
     Altoona County.rb is a Ruby file/crawler which Scraps the Inmate Details from Altoona County
    URL => "http://inmatelocator.cor.state.pa.us/inmatelocatorweb/"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")                     # Joins The scrape.rb file which opens a webpage and stores the details into Database
require 'rubygems'

STATE = "Pennsylvania"
COUNTY = "Altoona County"
CITY = "Altoona"

BASE = "http://inmatelocator.cor.state.pa.us/inmatelocatorweb/"                    # Base URL to get the details 
DETAIL="http://inmatelocator.cor.state.pa.us/inmatelocatorweb/criteria.aspx"          # Detail URL for posting data's
DETAIL1="http://inmatelocator.cor.state.pa.us/inmatelocatorweb/InmLocator.aspx"      # Detail1 URL for posting data's
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)          # Initilaized the Scrape Class
basedoc=scrape.get(BASE)
view_state_value=basedoc.css('input')[0]['value']
arrest = DFG::Arrest.new()         # Initilaizing object of Arrest Class
for i in "A".."Z"                                                  # loops through A to Z from first name to open the Inmate search page
 for j in "A".."Z"                                                  # loops through A to Z from last name to open the Inmate search page
post_args = {
 '__VIEWSTATE' => basedoc.css('input')[0]['value'],

 'btnSearch'=>'Find Inmate',
 'cboCitizenship'=>'---',
 'cboCommCnty'=>'---',
 'cboLocation'=>'---',
 'cboRace'=>'---',
 'cboSex'=>'---',
 'grpAgeDOB'=>'radDOB',
 'radList'=>'radNam',
 'txtDobAge'=>'',
 'txtFrstNm'=>"#{i}",
 'txtInmNo'=>'',
 'txtLstNm'=>"#{j}",
 'txtMidNm'=>''
}

 doc2 = scrape.post(DETAIL, post_args)        #Posting Arguments to open Inmate Locator Results 
 count=doc2.css('#dtlPageNum').css('tr td').size

  
 for k in 0..count-1
post_args2 ={
 '__EVENTARGUMENT' => '',
 '__EVENTTARGET' =>	"dtlPageNum:_ctl#{k}:lBtnPageNum",
 '__VIEWSTATE'=>doc2.css('input')[2]['value']
  }
   
    doc3 = scrape.post(DETAIL1, post_args2)      #Posting Arguments to open Inmate Locator Results 
  doc3.css('tr.clstdfield').each {|p|
  fname= p.css('td')[1].inner_html.strip! rescue ""      # Scraps First Name
    mname= p.css('td')[2].inner_html.strip! rescue ""   # Scraps Middle Name
      lname= p.css('td')[3].inner_html.strip! rescue ""    # Scraps Last Name
      p name= "#{fname}, #{mname} #{lname}".gsub('&#160;',' ')
        arrest.name = name                # Inserts name
        scrape.add(arrest)
scrape.commit()		# Commits Executed Datas
  }

end
end
end
=begin
    Wisconsin	Milwaukee County-Milwaukee.rb is a Ruby file/crawler which Scraps the Offender Details from Wisconsin-Milwaukee County-Milwaukee
    URL => "http://www.inmatesearch.mkesheriff.org/"!!!      
=end
require File.join(File.dirname(__FILE__), "scrape.rb")		 # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Wisconsin"
COUNTY = "MILWAUKEE County"
CITY = "MILWAUKEE"

BASE="http://www.inmatesearch.mkesheriff.org/"			 # Base URL to get the details 

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)			  # Initializing object of Scrape Class

doc = scrape.get(BASE)									# Opens the Base Url for Scrapping
 arrest = DFG::Arrest.new()	 # Initilaizing object of Arrest Class
for j in "a".."z"										# loops through a to z from first name to open the offender details page

  post_args = {
    '__EVENTTARGET' => doc.css('input#__EVENTTARGET')[0]['value'],
    '__EVENTVALIDATION' => doc.css('input#__EVENTVALIDATION')[0]['value'],
    '__LASTFOCUS' => doc.css('input#__LASTFOCUS')[0]['value'],							# Posts The arguments to get the page details
    '__VIEWSTATE' => doc.css('input#__VIEWSTATE')[0]['value'],
    'ctrlUsrSrchTools$lstGender'=>"U",
    'ctrlUsrSrchTools$txtFirstName'=>"#{j}",
    'ctrlUsrSrchTools$cmdSearch'=>'Search'
  }

doc1 = scrape.post(BASE, post_args)
size=doc1.css('#frmDefault').css('table').css('tbody tr').size			# takes the document size

  for i in 0..size-1
    name1=doc1.css('#frmDefault').css('table').css('tbody tr')[i].css('td')[1].to_s.split('<nobr>').last.split('</nobr>').first.gsub(/\s+/, " ").strip.split(',').first rescue ""	# Scraps Name
    word=doc1.css('#frmDefault').css('table').css('tbody tr')[i].css('td')[1].to_s.split('<nobr>').last.split('</nobr>').first.split(',').last.split('').last rescue ""		
    name2=doc1.css('#frmDefault').css('table').css('tbody tr')[i].css('td')[1].to_s.split('<nobr>').last.split('</nobr>').first.split(',').last.split(word).last rescue ""
    name="#{name1}, #{name2}" rescue ""
     arrest.name=name	# Inserts Name
     scrape.add(arrest)	# Executes Inserted Records
     scrape.commit()		# Commits Executed Records
   end
 
end

=begin
     Minnesota County.rb is a Ruby file/crawler which Scraps the Offender Details from Minneosta County
    URL => "http://www.doc.state.mn.us/publicviewer/main.asp"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "Minnesota"
COUNTY = "Minnesota  County"
CITY = "Minnesota"
BASE="http://www.doc.state.mn.us/publicviewer/main.asp" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
DETAIL="http://www.doc.state.mn.us/publicviewer/ResultsList.asp" # Detail URL for posting data's
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
for i in "a".."z"					# loops through a to z from first name to open the offender details page
post_args = {
'txtDateofbirth' => '',
'txtFirstName' =>"#{i}",				# Posts Arguments
'txtLastName' => '',
'txtOID' => ''
}

document=scrape.post(DETAIL,post_args)	# Posting Arguments to open Offenders Page
 document.css('font a').each {|i|
link=URI.encode("http://www.doc.state.mn.us/publicviewer/#{i['href']}") rescue ""	# Link to open Each offender Page
docs=scrape.get(link)
 img1=docs.css('td td img')[0]['src'] rescue ""
  imag1=URI.encode("http://www.doc.state.mn.us/publicviewer/#{img1}") rescue ""		# Scraps Image1
 img2=docs.css('td td img')[1]['src'] rescue ""
 imag2=URI.encode("http://www.doc.state.mn.us/publicviewer/#{img2}") rescue ""		# Scraps Image2
  nam= docs.css('td tr:nth-child(3) td:nth-child(2)').inner_html rescue ""	 		# Name of Offender
 date= docs.css('tr:nth-child(7) td:nth-child(2)').inner_html rescue ""				# Booking Date of Offender
 descr= docs.css('tr:nth-child(14) a').inner_html rescue ""							# Description Of Offender
  name= nam.split(' ').join(' ,') rescue ""
 fname=name.split(',')[0] rescue ""
 size=name.split(',').size rescue ""
 lname=name.split(',')[1..size].join('') rescue ""

arrest.image1=imag1 rescue ""				# Insersts Image1
arrest.image2=imag2 rescue ""				# Inserts Image2
if !date.empty?
	arrest.date=Date.strptime(date,"%m/%d/%Y").to_s rescue '' # Inserts Date
end
arrest.name=fname+' ,'+lname	rescue ""	# Inserts Date
bond=0
desc=descr 
	arrest.add_charge(desc, bond)    	# Inserts Charges
scrape.add(arrest)		#Executes Inserted Records
scrape.commit()		# Commits Executed Datas To DB

}

end
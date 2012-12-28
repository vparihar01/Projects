=begin
     OHIO County.rb is a Ruby file/crawler which Scraps the Offender Details from OHIO County
    URL => "http://www.drc.ohio.gov/offendersearch/search.aspx"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "OHIO"
COUNTY = "OHIO County"
CITY = "OHIO"
BASE="http://www.drc.ohio.gov/offendersearch/search.aspx" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class

doce=scrape.get(BASE)
view_state=doce.css('input')[7]['value']
DETAILEDURL="http://www.drc.ohio.gov/offendersearch/Results.aspx"
DETAIL="http://www.drc.ohio.gov/offendersearch/search.aspx" # Detail URL for posting data's
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
for i in "a".."z"					# loops through a to z from first name to open the offender details page
post_args = {
'DDL_ComCounty'=>'',
'DDL_Number'=>'A',
'DDL_ResCounty'=>'',
'DDL_Sort'=>'N',
'RBL_Status'=>'B',
'SearchButton'=>'Search',
'__EVENTARGUMENT'=>'',
'__EVENTTARGET'=>'',														# POSTING ARGUMENTS TO OPEN THE WEB PAGE
'__VIEWSTATE'=>"#{view_state}",
'txtFirstName'=>'',
'txtIdnumber'=>'',
'txtLastName'=>"#{i}",
'txtPBMonYr'=>'',
'txtZip'=>''		
}
descr=" "
document=scrape.post(DETAIL,post_args)											# Posting Arguments to open Offenders Page
count=document.css('span#Lbl_pageCount.colText').inner_html.split('of').last.to_i rescue ""	
	for j in 1..count
		document.css('#DG_OffenderList td:nth-child(3) a').each {|m|
			id=URI.encode("http://www.drc.ohio.gov/offendersearch/#{m['href']}")		# Getting the full webpath to open offender page
			offender_page=scrape.get(id)
			descr=""
			p name=offender_page.css('span#Lbl_FullName.colText').inner_html rescue ""				# Extracting Name
			p date=offender_page.css('span#Lbl_AdminDateData.colText').inner_html rescue ""			# Extracting Date
			img=offender_page.css('#Img_Offender').to_html.split('"')[3].gsub('%5C','\\') rescue ""		# Extacting Image Path
			 p image=URI.encode("http://www.drc.ohio.gov/offendersearch/#{img}") rescue ""	
			 offender_page.css('.colText td:nth-child(1) .coltextlbl').each { |a|
			  descr= a.inner_html+ ' ,'+ descr	 rescue ""										# Extracting Description
			 }
			p descr 
			arrest.name=name				# Inserting Name
			arrest.image1=image			# Inserting Image
			if !date.empty?	
				arrest.date = DateTime.strptime(date, "%m/%d/%Y") rescue ""		# Inserting Date
			end
			arrest.add_charge(descr, bond=0)		# Inserting Charges
			scrape.add(arrest)					# Executing Inserted Datas
			scrape.commit()					# Commiting Executed Datas
		}
		  view=document.css('input')[2]['value']
		 post_argumnt= {
			'__EVENTARGUMENT'=> '',
			'__EVENTTARGET'=>'LB_Next1',
			'__VIEWSTATE'=>"#{view}",
			'client'=>'ohio_gov',						# Posting Arguments to loop through each Pages
			'output'=>'xml_no_dtd',
			'proxystylesheet'=>'ohio_gov',
			'q'=>'search'
			}
			document=scrape.post(DETAILEDURL,post_argumnt)   # Overriding The variable document to get next page offender links/id
			
	end

end
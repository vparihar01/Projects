=begin
     COLORADO County.rb is a Ruby file/crawler which Scraps the Offender Details from COLORADO County
    URL => "http://www.doc.state.co.us/find-inmate"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "COLORADO"
COUNTY = "COLORADO County"
CITY = "COLORADO"
BASE="http://www.doc.state.co.us/oss/" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
DETAIL="http://www.doc.state.co.us/oss/controller/ctl_ajax.php" # Detail URL for posting data's
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
cnt=50
 for i in "a".."z"					# loops through a to z from first name to open the offender details page
	post_args = {
	'dob'=>'',
	'docno'=>'',
	'fnam'=>'',
	'gender'=>'ALL',
	'lnam'=>"#{i}",
	'order_col'=>'undefined',
	'order_dir'=>'undefined',
	'range'=>'false',
	'search'=>'true',
	'sec'=>'list_offenders',
	'start'=>0
	}
	
	 document=scrape.post(DETAIL,post_args)					#Posting Arguments to open Offender Page
	 total_records= document.css('.section_data div:nth-child(1)').inner_html.split('of').last.to_i rescue ""	# EXTRACTS TOTAL RECORDS
	 count=total_records/50 rescue ""
	  rem=total_records%50 rescue ""
	if rem
		count=count+1						# ADDS 1 IF THERE IS ANY REMAINDER
	end
	
	for i in 1..count-1
	 document.css('tr td[2]').each {|p|
	id= p.inner_html rescue ""
	post_arguments= {
	'docno'=>"#{id}",
	'sec'=>'offender_profile'
	}
	offender_page=scrape.post(DETAIL,post_arguments) rescue ""
	img= offender_page.css('a img').to_html.split('"')[1] rescue ""
	image=URI.encode("http://www.doc.state.co.us#{img}") rescue ""				# Scraps Image
	name=offender_page.css('td[2]').css('td div')[0].inner_html.strip! rescue ""		# Scraps Name
	arrest.name=name
	arrest.image1=image
	arrest.add_charge(NIL,0)
	scrape.add(arrest)
	scrape.commit()
	}
	
	post_argus = {
	'dob'=>'',
	'docno'=>'',
	'fnam'=>'',
	'gender'=>'ALL',
	'lnam'=>"#{i}",
	'order_col'=>'offender_name',						# Posts Arguments to click on the next page
	'order_dir'=>'ASC',
	'range'=>'false',
	'search'=>'false',
	'sec'=>'list_offenders',
	'start'=> "#{cnt}"
	}
	
	 document=scrape.post(DETAIL,post_argus)
	 cnt+=50											# incrementing count by 50
	
	
	end
	
 end

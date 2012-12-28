=begin
     NEW MEXICO County.rb is a Ruby file/crawler which Scraps the Offender Details from NEW MEXICO County
    URL => "http://corrections.state.nm.us:8080/ofndrsearch/"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "NEW MEXICO"
COUNTY = "NEW MEXICO County"
CITY = "NEW MEXICO"
BASE="http://corrections.state.nm.us:8080/ofndrsearch/" # Base URL to get the details 
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)  # Initilaized the Scrape Class
DETAIL="http://corrections.state.nm.us:8080/ofndrsearch/history_search_results.do" # Detail URL for posting data's
DETAILEDURL="http://corrections.state.nm.us:8080/ofndrsearch/history_detail.do"
arrest = DFG::Arrest.new()				 # Initilaizing object of Arrest Class
for i in "a".."z"					# loops through a to z from first name to open the offender details page
post_args = {
'Add'=>'Search',
'first_name' => '',
'last_name' => "a",
'nmcd_number'=> '',
'ofndr_number' => ''	
}
desc=""
document=scrape.post(DETAIL,post_args)	# Posting Arguments to open Offenders Page
      document.css('td.intro').css('form').each { |l|
      
	id=l.css('td')[5].inner_html
	 fname=l.css('td')[1].inner_html.strip!
	 lname =l.css('td')[0].inner_html.strip! 
	p name ="#{fname}, #{lname}"
	arrest.name=name
			post_arguments= {
				'Submit'=>'View Details',
				'ofndr_number'=>"#{id}"
			}

	docs=scrape.post(DETAILEDURL,post_arguments)
	image=docs.css('.intro img').to_html.split('"')[1] rescue ""
	 arrest.image1=image
	docs.css('.intro td:nth-child(1) table').css('tr').each { |k|
	desc="#{k.css('td').inner_html } , #{desc}" rescue ""
	}
	desc.gsub("<br>","").gsub("</br>",'').gsub('<td>','').gsub('</td>').gsub('<b>','</b>').gsub('<!-- <td>Date Pending</td>\r\n\t\t\t\t\t\t\t-->','').strip! rescue ""
	arrest.add_charge(desc,0)
	scrape.add(arrest)
	scrape.commit()
	desc=""
}
desc=""
p "******************************************************************************************************************"
end
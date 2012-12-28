=begin
     Vermont Chittenden County-Burlington.rb is a Ruby file/crawler which Scraps the Offender Details from Chittenden County
    URL => "http://doc.vermont.gov/offender-locator/"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database
STATE = "vermont"
COUNTY = "Chittenden County"
CITY = "Burlington"
BASE="http://doc.vermont.gov/offender-locator/"   # Base URL to get the details 
DETAILEDURL="http://doc.vermont.gov/offender-locator/offender-locator/Offender_report"  # Detailed URL for posting data's

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)                # Initializing object of Scrape Class
arrest = DFG::Arrest.new()                                                             # Initilaizing object of Arrest Class
 
doc=scrape.get(BASE)									# Opens the page and saves in doc(Variable)
for i in "a".."z"						# loops through a to z from first name to open the offender details page
	
 post_args = {							# posting arguments 
	'lname'=>'',
	'fname'=>	"#{i}",				# passing values i.e a,b,c .... z
	'fieldset'=>'default',
	'form.submitted'=>1,
	'add_reference.field:record'=>'',
	'add_reference.type:record'=>'',
	'add_reference.destination:record'=>'',
	'last_referer'=>'	http://doc.vermont.gov/offender-locator',
	'form_submit'=>'Submit'
 }
 
 doc1 = scrape.post(DETAILEDURL, post_args)     # posting arguments to open the offeder details page
 size=doc1.css('tr').size
 (1..size-1).each { |person|
	 lastname=doc1.css('tr')[person].css('td')[2].inner_html.to_s.strip rescue ''		# scraps the last name
	 firstname=doc1.css('tr')[person].css('td')[1].inner_html.to_s.strip rescue ''		# scraps the first name
	 name=[firstname,lastname].join(',')										# joins both lname and fname using comma operator
	 if (name!="")
	   arrest.name=name			# inserts into name DB
	 end
	 scrape.add(arrest)			# Executes the Database
	 scrape.commit()			# Commits the Executed Data
	}
 end
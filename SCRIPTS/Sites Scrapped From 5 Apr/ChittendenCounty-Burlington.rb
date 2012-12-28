require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "vermont"
COUNTY = "vermont  County"
CITY = "vermont"
BASE="http://doc.vermont.gov/offender-locator/"
DETAILEDURL="http://doc.vermont.gov/offender-locator/offender-locator/Offender_report"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
arrest = DFG::Arrest.new()

doc=scrape.get(BASE)
for i in "a".."z"
	
 post_args = {
	'lname'=>'',
	'fname'=>	"#{i}",
	'fieldset'=>'default',
	'form.submitted'=>1,
	'add_reference.field:record'=>'',
	'add_reference.type:record'=>'',
	'add_reference.destination:record'=>'',
	'last_referer'=>'	http://doc.vermont.gov/offender-locator',
	'form_submit'=>'Submit'
 }
 
 doc1 = scrape.post(DETAILEDURL, post_args)
 size=doc1.css('tr').size
 (1..size-1).each { |person|
	 lastname=doc1.css('tr')[person].css('td')[2].inner_html.to_s.strip rescue ''
	 firstname=doc1.css('tr')[person].css('td')[1].inner_html.to_s.strip rescue ''
	 name=[firstname,lastname].join(',')
	 if (name!="")
	   arrest.name=name
	 end
	 scrape.add(arrest)
	 scrape.commit()
	}
 end
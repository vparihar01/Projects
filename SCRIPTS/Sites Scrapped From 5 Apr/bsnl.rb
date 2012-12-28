require File.join(File.dirname(__FILE__), "scrape.rb")

STATE = "Chattisgarh"
COUNTY = "India"
CITY = "Raipur"

BASE = "http://www.chhattisgarh.bsnl.co.in/%28S%28231nrx45dicgaa452oi51y55%29%29/directory_services/AreaWiseSearch.aspx?Area=04"
DETAIL = "http://www.chhattisgarh.bsnl.co.in/(S(231nrx45dicgaa452oi51y55))/directory_services/AreaWiseSearch.aspx?Area=04"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)
VIEWSTATE=doc.css('input')[2]['value']
EVENTVALIDATION= doc.css('input').last['value']
post_args= {
'Button1'=>'Search',
'DropDownList2'=>'BAGBAHARA',
'Search'=>'rdbName',
'__EVENTARGUMENT'=>'',
'__EVENTTARGET'=>'',
'__EVENTVALIDATION'=>EVENTVALIDATION,
'__PREVIOUSPAGE'=>'KxE3cYvcdFqskKzugcKpBz3YBu-vxODzzJloKC__r8lpYIuGkShNvCLAh9-NhpN_0',
'__VIEWSTATE'=>VIEWSTATE,
'drpMatch'=>'Anywhere',
'txtSearch'=>''
}

document=scrape.post(DETAIL,post_args)
document.css('#dgrSearch td').each { |t|
p t.inner_html.strip!
p "**********************"
}

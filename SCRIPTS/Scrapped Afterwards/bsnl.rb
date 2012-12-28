require 'rubygems'
require 'mechanize'
require 'open-uri'
URL="http://www.chhattisgarh.bsnl.co.in/(S(onhm3155wk1xkw452d5nlxq3))/directory_services/AreaWiseSearch.aspx?Area=04"
@agent = Mechanize.new
page=@agent.get('http://www.chhattisgarh.bsnl.co.in/(S(onhm3155wk1xkw452d5nlxq3))/directory_services/AreaWiseSearch.aspx?Area=04')
areasearch=page.form_with(:action => "AreaWiseSearch.aspx?Area=04")
areasearch["txtSearch"]="a"
areasearch["drpMatch"]="Starting With"
areasearch["DropDownList2"]="BAGBAHARA"
data=@agent.submit(areasearch,areasearch.button_with(:value =>"Search"))
 data.parser.css("#pnlGrid").css("tr").each { |u|
  u.css("td").each {|i| puts i.css("font").inner_html.strip! }
 p "***********************"
 }
 
 
 
 #~ require 'rubygems'
#~ require 'mechanize'
#~ require 'open-uri'
#~ URL="http://www.chhattisgarh.bsnl.co.in/(S(onhm3155wk1xkw452d5nlxq3))/directory_services/AreaWiseSearch.aspx?Area=04"
#~ @agent = Mechanize.new
#~ page=@agent.get('http://www.chhattisgarh.bsnl.co.in/(S(onhm3155wk1xkw452d5nlxq3))/directory_services/AreaWiseSearch.aspx?Area=04')
#~ areasearch=page.form_with(:action => "AreaWiseSearch.aspx?Area=04")
#~ areasearch["txtSearch"]="a"
#~ areasearch["drpMatch"]="Starting With"
#~ areasearch["DropDownList2"]="BAGBAHARA"
#~ data=@agent.submit(areasearch,areasearch.button_with(:value =>"Search"))
#~ data.parser.css("#pnlGrid").css("tr").each { |u|
#~ u.css("td").each {|i| puts i.css("font").inner_html.strip! }
#~ p "***********************"
#~ }
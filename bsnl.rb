require 'rubygems'
require 'mechanize'
require 'open-uri'

#agent=Mechanize.new
URL="http://www.chhattisgarh.bsnl.co.in/(S(onhm3155wk1xkw452d5nlxq3))/directory_services/AreaWiseSearch.aspx?Area=04"
agent = Mechanize.new
page=agent.get('http://www.chhattisgarh.bsnl.co.in/(S(onhm3155wk1xkw452d5nlxq3))/directory_services/AreaWiseSearch.aspx?Area=04')
temp_jar=agent.cookie_jar
puts page.response 
@agent = Mechanize.new
@agent.cookie_jar = temp_jar
areasearch=page.form_with(:action => "AreaWiseSearch.aspx?Area=04")
areasearch["txtSearch"]="a"
areasearch["drpMatch"]="Starting With"
areasearch["Search"]="rdbName"
areasearch["DropDownList2"]="BAGBAHARA"
areasearch.fields.each { |f| puts "#{f.name} : #{f.value}" }

hash={"txtSearch"=>"a","drpMatch"=>"Starting With","Search"=>"rdbName","DropDownList2"=>"BAGBAHARA"}
 main_page=@agent.post(URL,hash)
p main_page.parser.to_html

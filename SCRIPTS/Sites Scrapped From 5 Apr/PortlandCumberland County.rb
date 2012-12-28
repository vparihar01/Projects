require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "Cumberland"
COUNTY = "Cumberland County"
CITY = "Cumberland"
BASE = "http://www.cumberlandso.org/Fugitive%20Files/captured.htm"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = Nokogiri::HTML(open(BASE))
size=doc.css('#mainContent').css('td').size
image=[]
name=[]
charges=[]
baseurl="http://www.cumberlandso.org"
for i in 0..size-1
	if (doc.css('#mainContent').css('tr td')[i].css('h5')[1])
 name1=doc.css('#mainContent').css('tr td')[i].css('h5')[1].inner_html
 name<<name1
		else
			name2=doc.css('#mainContent').css('tr td')[i].css('h5')[0].inner_html
			name<<name2
		end
		end

for i in 0..size-1
image1=doc.css('#mainContent').css('td')[i].css('img').to_s.split('..').last.split(' alt').first.chop
image_string=baseurl+image1
image<<image_string
end
 
for i in 0..size-1
	arrest = DFG::Arrest.new()
	arrest.image1=image[i]
	arrest.name=name[i]
	scrape.add(arrest)
  scrape.commit()
end

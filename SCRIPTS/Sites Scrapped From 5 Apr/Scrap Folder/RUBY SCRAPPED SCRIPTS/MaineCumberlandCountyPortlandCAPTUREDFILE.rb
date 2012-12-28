=begin
      Maine-Cumberland County-Portland captured.rb is a Ruby file/crawler which extracts the image,name and description of captured Offenders separately    
=end

require File.join(File.dirname(__FILE__), "scrape.rb")	# joins the file scrape.rb
STATE = "Cumberland"
COUNTY = "Cumberland County"
CITY = "Cumberland"
BASE = "http://www.cumberlandso.org/Fugitive%20Files/captured.htm"	 # base url to get datas 
	
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = Nokogiri::HTML(open(BASE))																								#Nokogiri is used for scrap
size=doc.css('#mainContent').css('td').size			
	#Initializing the arrays
image=[]																																												#Initializing the arrays
name=[]

baseurl="http://www.cumberlandso.org"
for i in 0..size-1
	if (doc.css('#mainContent').css('tr td')[i].css('h5')[1])
		 name1=doc.css('#mainContent').css('tr td')[i].css('h5')[1].inner_html rescue ''		# scraps name		
		 name<<name1																																																				#Getting the name
	else
		 name2=doc.css('#mainContent').css('tr td')[i].css('h5')[0].inner_html rescue ''		
		 name<<name2																																																				#Getting the name
	end
end

for i in 0..size-1
		image1=doc.css('#mainContent').css('td')[i].css('img').to_s.split('..').last.split(' alt').first.chop rescue ''	# scraps images	
		image_string=baseurl+image1
		image<<image_string																																																																				#Getting the image
end
	 
for i in 0..size-1
		arrest = DFG::Arrest.new()		# initializes Arrest object																#Storing all the details in DataBase
		arrest.image1=image[i]		# inserts image
		arrest.name=name[i]		# inserts name
		scrape.add(arrest)			# Executes inserted datas
		scrape.commit()			# commits executed datas
end

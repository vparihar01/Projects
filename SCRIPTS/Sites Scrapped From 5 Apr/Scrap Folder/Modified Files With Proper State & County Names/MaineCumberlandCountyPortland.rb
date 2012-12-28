=begin
      Maine-Cumberland County-Portland.rb is a Ruby file/crawler which extracts the image,name and description     
=end

require File.join(File.dirname(__FILE__), "scrape.rb") # joins the file scrape.rb

STATE = "Cumberland"
COUNTY = "Cumberland County"
CITY = "Cumberland"
BASE = 	"http://www.cumberlandso.org/Fugitive%20Files/mostwanted.htm"  # base url to get datas 

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)	# scrape object for SCrape Class in scrape.rb

doc = Nokogiri::HTML(open(BASE))													#Nokogiri is used for scrap
size=doc.css('#mainContent').css('td').size							

image=[]																		#Initializing the arrays
name=[]
charges=[]

baseurl="http://www.cumberlandso.org"									
for i in 0..size-1
	image1=doc.css('#mainContent').css('td')[i].css('img').to_s.split('..').last.split(' alt').first.chop rescue ''			
	image_string=baseurl+image1
	image<<image_string																																																																			                      	#Getting the image
	name<<doc.css('#mainContent').css('td')[i].css('h5').inner_html.split('<br>').first rescue ''	# scraps name																					#Getting the name
	charges<<doc.css('#mainContent').css('td')[i].css('h6')[2].inner_html.split(': ').last.split('<br>').first rescue ''			      #Getting the descriptions
	end
		for j in 0..size-1																					            #storing all the details in DB
			  arrest = DFG::Arrest.new()		# initializes Arrest object
				arrest.image1=image[j]	# inserts image
				arrest.name=name[j]	# inserts name
				arrest.add_charge(charges[j], 0)	# inserts charges
				scrape.add(arrest)	# Executes inserted datas
				scrape.commit()	# commits executed datas
 end



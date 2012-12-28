=begin
     Kentucky County.rb is a Ruby file/crawler which Scraps the Offender Details from KentuckyCounty
    URL => "http://apps.corrections.ky.gov/KOOL/ioffres.asp"!!!      
=end

require File.join(File.dirname(__FILE__), "scrape.rb")    # Joins The scrape.rb file which opens a webpage and stores the details into Database

STATE = "Kentucky"
COUNTY = "Kentucky County"
CITY = "Kentucky"

BASE = "http://apps.corrections.ky.gov/KOOL/ioffres.asp"	# Base URL to get the details 
DETAILEDURL = "http://apps.corrections.ky.gov/KOOL/ioffres.asp"	# Detail URL for posting data's

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)	# Initilaized the Scrape Class
doc = scrape.get(BASE)		# opens the base url

begin
  "a".upto("z") do |alphabet|
    # Search by name, one by one it will insert the alphabets, after
    # we submit the form and get the page with information
    post_args = "LName=&FName=#{alphabet}&MName=&Order=Default+%28Inmate+Last+Name%2C+First+Name%29&Action=Search"
    doc1 = scrape.post(DETAILEDURL, post_args)
    total_pages =  doc1.xpath("//td[@valign='CENTER']").text != "" ? doc1.xpath("//td[@valign='CENTER']").text.split("of")[1].strip : "1"

    # Here i get the total page list and parse the pages one by one
    (1..total_pages.to_i).each do |page_no|
      post_args = "Action=Scroll&InmateID=&LName=&FName=a%25&MName=&Archive=&Inst=&Race=&Sex=Any&Age=&Sens=&Alias=&CRDate=&CODate=&STDate=&RLDate=&Cty=&Order=Default+%28Inmate+Last+Name%2C+First+Name%29&Ind=&IndCty=&pagenum=#{page_no}"
      doc2 = scrape.post(DETAILEDURL, post_args)

      # Here i get the all persons information for this specific page
      # after, open the page and parse those informations
      a = doc2.xpath("//td[@valign='top']/a/@href")
      a.each do |temp_url|
        arrest = DFG::Arrest.new()					# Creates An object Of Arrest Class
        inner_url = "http://apps.corrections.ky.gov/KOOL/#{temp_url.text}"
        inner_doc = Nokogiri::HTML(open(inner_url))
        arrest.name = inner_doc.xpath("//table/tr/td[1]/pre").text.split("\t").first.split("Name:").last.strip.gsub(":", "").gsub('Min Date','') rescue ""	# Inserts Name
        arrest.date = Date.strptime(inner_doc.xpath("//table/tr/td[1]/pre").text.split("Inst Start Date:").last.strip.gsub("/", "-"), "%m-%d-%Y").to_s	# Inserts date
        arrest.image1 = "http://apps.corrections.ky.gov#{inner_doc.xpath("//table/tr/td[2]/img/@src").text}"	# inserts image
        desc = inner_doc.xpath("//table/tr[3]/td/b/font[2]").text
        bond = 0
        arrest.add_charge(desc, bond)	# inserts charges

        scrape.add(arrest) # Executes Inserted Records
        scrape.commit()	# Commits Executed Datas
      end
    end
  end
rescue
end

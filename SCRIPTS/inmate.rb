require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "MILWAUKEE"
COUNTY = "MILWAUKEE County"
CITY = "MILWAUKEE"

BASE="http://www.inmatesearch.mkesheriff.org/"

scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)

doc = scrape.get(BASE)

for j in "a".."z"

  post_args = {
    '__EVENTTARGET' => doc.css('input#__EVENTTARGET')[0]['value'],
    '__EVENTVALIDATION' => doc.css('input#__EVENTVALIDATION')[0]['value'],
    '__LASTFOCUS' => doc.css('input#__LASTFOCUS')[0]['value'],
    '__VIEWSTATE' => doc.css('input#__VIEWSTATE')[0]['value'],
    'ctrlUsrSrchTools$lstGender'=>"U",
    'ctrlUsrSrchTools$txtFirstName'=>"#{j}",
    'ctrlUsrSrchTools$cmdSearch'=>'Search'
  }

doc1 = scrape.post(BASE, post_args)
size=doc1.css('#frmDefault').css('table').css('tbody tr').size

  for i in 0..size-1
    name1=doc1.css('#frmDefault').css('table').css('tbody tr')[i].css('td')[1].to_s.split('<nobr>').last.split('</nobr>').first.gsub(/\s+/, " ").strip.split(',').first rescue ""
    word=doc1.css('#frmDefault').css('table').css('tbody tr')[i].css('td')[1].to_s.split('<nobr>').last.split('</nobr>').first.split(',').last.split('').last rescue ""
    name2=doc1.css('#frmDefault').css('table').css('tbody tr')[i].css('td')[1].to_s.split('<nobr>').last.split('</nobr>').first.split(',').last.split(word).last rescue ""
    name="#{name1}, #{name2}" rescue ""
      arrest = DFG::Arrest.new()
     arrest.name=name
     scrape.add(arrest)
     scrape.commit()
   end
 
end

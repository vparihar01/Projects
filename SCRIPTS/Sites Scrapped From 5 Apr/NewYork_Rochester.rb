require File.join(File.dirname(__FILE__), "scrape.rb")
STATE = "New York"
COUNTY = "Rochester County"
CITY = "New York"
BASE="http://nysdoccslookup.doccs.ny.gov/"
DETAIL="http://nysdoccslookup.doccs.ny.gov/GCA00P00/WIQ1/WINQ000"
DETAIL1="http://nysdoccslookup.doccs.ny.gov/GCA00P00/WIQ3/WINQ130"
scrape = DFG::Scrape.new(STATE, COUNTY, CITY, BASE)
basedoc=scrape.get(BASE) 
dfh_state_token=basedoc.css('input')[14]['value']
k01=basedoc.css('input')[13]['value']
for i in "a".."z"

	post_args={
		'DFH_MAP_STATE_TOKEN'=>'',
		'DFH_STATE_TOKEN'=>"#{dfh_state_token}",
		'K01'=>"#{k01}",
		'M00_DIN_FLD1I'=>'',	
		'M00_DIN_FLD2I'=>'',	
		'M00_DIN_FLD3I'=>'',	
		'M00_DOBCCYYI'=>'',	
		'M00_FIRST_NAMEI'=>'',
		'M00_LAST_NAMEI'=>"#{i}",
		'M00_MID_NAMEI'=>'',	
		'M00_NAME_SUFXI'=>'',	
		'M00_NYSID_FLD1I'=>'',	
		'M00_NYSID_FLD2I'=>''	
	}
		doc = scrape.post(DETAIL, post_args)
	loop do
		k002=doc.css('input')[49]['value']
		dfh=doc.css('input')[54]['value']
	val=1
	p doc.css('input').to_html 
	doc.css('input').each {|o|
	p "************************8"
		p SEL=o['value'] if(o.to_html.include?('M13_SEL_DINI'))
		p KO1=o['value'] if(o.to_html.include?('K01'))
		p KO2=o['value'] if(o.to_html.include?('K02'))
		p KO4=o['value'] if(o.to_html.include?('K04'))
		p KO5=o['value'] if(o.to_html.include?('K05'))
		p KO6=o['value'] if(o.to_html.include?('K06'))
		p TKN=o['value'] if(o.to_html.include?('DFH_STATE_TOKEN'))
	  post_argument={
		'DFH_MAP_STATE_TOKEN'=>'',	
		'DFH_STATE_TOKEN'=>"#{TKN}",
		'K01'=>"#{KO1}",
		'K02'=>"#{K02}",
		'K03'=>'',	
		'K04'=>"#{K04}",	
		'K05'=>"#{K05}",	
		'K06'=>"#{K06}",	
		'M13_PAGE_CLICKI'=>'',	
		'M13_SEL_DINI'=>"#{SEL}",
		"din#{val}"=>"#{SEL}"
		}
	
	doc.css('td:nth-child(2)').each {|t|
		p t.inner_html.strip!
	} 
		post_args1={
			'DFH_MAP_STATE_TOKEN'=>'',	
			'DFH_STATE_TOKEN'=>"#{dfh}",
			'K01'=>'WINQ130',
			'K02'=>"#{k002}",
			'K03'=>'',	
			'K04'=>'1',
			'K05'=>'2',
			'K06'=>'1',
			'M13_PAGE_CLICKI'=>'Y',
			'M13_SEL_DINI'=>'',	
			'next'=>'Next 4 Inmate Names'
		}
		doc=scrape.post(DETAIL1, post_args1)
val+=1
	content=doc.css('div.center input').to_html
	break if (content.empty?)
	}
end

end


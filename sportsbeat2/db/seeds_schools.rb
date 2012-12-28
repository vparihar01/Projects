School.transaction do
  school = School.new
  school.id = 1
  school.name = "SportsBeat High"
  school.address = "4540 Campus Drive"
  school.city = "Newport Beach"
  school.county = "Orange County"
  school.state = "CA"
  school.zip = "92660"
  school.latitude = "33.670765"
  school.longitude = "-117.866477"
  school.timezone = "America/Los_Angeles"
  school.mascot = "Bandits"
  school.primary_color = "red"
  school.secondary_color = "gray"
  school.save!

  school = School.new
  school.id = 27057
  school.name = "Bayside High School"
  school.address = "1438 N Gower St"
  school.city = "Los Angeles"
  school.county = "Los Angeles County"
  school.state = "CA"
  school.zip = "92660"
  school.latitude = "34.096905"
  school.longitude = "-118.322296"
  school.timezone = "America/Los_Angeles"
  school.mascot = "Tigers"
  school.primary_color = "Red"
  school.secondary_color = "White"
  school.save!
end
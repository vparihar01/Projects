Role.transaction do
  roles = MultiJson.load Rails.root.join("db", "seed_data", "roles.json")
  roles.each do |hash|
    role = Role.new hash
    role.save!
  end
end

User.transaction do
  user = User.new
  user.email = "admin@sportsbeat.com"
  user.first_name = "Sports"
  user.last_name = "Beat"
  user.email = "admin@sportsbeat.com"
  user.password = "password"
  user.gender = "male"
  user.skip_confirmation!
  user.save!
  user.roles << Role.find_by_name("admin")

  user = User.new
  user.email = "john@example.com"
  user.first_name = "John"
  user.last_name = "Doe"
  user.password = "password"
  user.gender = "male"
  user.skip_confirmation!
  user.save!
  user.roles << Role.find_by_name("athlete")

  user = User.new
  user.email = "jane@example.com"
  user.first_name = "Jane"
  user.last_name = "Doe"
  user.password = "password"
  user.gender = "female"
  user.skip_confirmation!
  user.save!
  user.roles << Role.find_by_name("athlete")

  surnames = MultiJson.load Rails.root.join("db", "seed_data", "surnames.json")
  surnames.shuffle!
  surnames.each do |surname|
    male = [true, false].sample
    user = User.new
    user.email = "#{surname.downcase}@example.com"
    user.first_name = male ? "John" : "Jane"
    user.last_name = surname
    user.gender = male ? "male" : "female"
    user.password = "password"
    user.skip_confirmation!
    user.save!
  end

  User.where('id > 3').find_each do |u|
    role_name = %w(athlete fan alumnus).sample
    u.roles << Role.find_by_name(role_name)
  end
end
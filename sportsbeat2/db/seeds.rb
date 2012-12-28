# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Users
load Rails.root.join('db', 'seeds_users.rb')

# Schools
load Rails.root.join('db', 'seeds_schools.rb')

# Sports and Positions
load Rails.root.join('db', 'seeds_sports.rb')

# Teams
load Rails.root.join('db', 'seeds_teams.rb')

# Athletes
load Rails.root.join('db', 'seeds_athletes.rb')

#Score Actions
load Rails.root.join('db', 'seeds_score_actions.rb')
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

role_list = %W(Manager Developer)
role_list.each {|name| Role.create( name: name) }

team_list = ['OpsWay1', 'OpsWay2', 'OpsWay3', 'OpsWay4']
team_list.each {|name| Team.create( name: name) }

user_list = [
  [ "Dev1", 50,   'dev1', 'OpsWay1', 'Developer' ],
  [ "Dev2", 60,   'dev2', 'OpsWay2', 'Developer' ],
  [ "Dev3", 70,   'dev3', 'OpsWay3', 'Developer' ],
  [ "Dev4", 80,   'dev4', 'OpsWay4', 'Developer' ]
]

user_list.each do |name, rate, login, team, role|
  User.create( name: name, daily_rate: rate, login: login, team: Team.find_by_name(team), role: Role.find_by_name(role) )
end

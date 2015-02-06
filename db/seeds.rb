# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


team_list = ['OpsWay1', 'OpsWay2', 'OpsWay3', 'OpsWay4', 'OpsWay5', 'Central Office']
team_list.each {|name| Team.create( name: name) }

role_list = %W(Manager Developer)
role_list.each {|name| Role.create( name: name) }

user_list = [
  [ "Dmitriy Ivanenko",       62,   'dmiva', 'OpsWay1', 'Developer' ],
  [ "Aleksandr Ishchenko",    27,   'altis', 'OpsWay1', 'Developer' ],
  [ "Volodymir Rudakov",      38,   'vorud', 'OpsWay3', 'Developer' ],
  [ "Stanislav Derebcinschi", 52,   'stder', 'OpsWay3', 'Developer' ],
  [ "Yuriy Kobrynyuk",        39,   'yukob', 'OpsWay2', 'Developer' ],
  [ "Stanislav Pivovartsev",  67,   'stpiv', 'OpsWay2', 'Developer' ],
  [ "Oksana Melnik",          69,   'okmel', 'OpsWay2', 'Manager' ],
  [ "Andrey Lebedinskiy",     78,   'anleb', 'OpsWay3', 'Manager' ],
  [ "Yurii Lunhol",           31,   'yulun', 'OpsWay2', 'Developer' ],
  [ "Ruslan Abdullaev",       62,   'ruabd', 'OpsWay5', 'Developer' ],
  [ "Nikita Kushnir",         52,   'nikus', 'OpsWay2', 'Developer' ],
  [ "Stas Morgun",            26,   'stmor', 'OpsWay3', 'Developer'],
  [ "Peter Kurbatsky",        31,   'pekub', 'OpsWay4', 'Developer' ],
  [ "Max Voronov",            57,   'mavor', 'OpsWay1', 'Developer' ],
  [ "Dmitrii Mikhailov",      49,   'dimih', 'OpsWay1', 'Developer' ],
  [ "Andriy Zherebchenko",    98,   'anzhe', 'OpsWay4', 'Developer' ],
  [ "Alexandr Vronskiy",      104,  'alvro', 'OpsWay1', 'Developer' ],
  [ "Alexander Dmitrienko",   72,   'aldmi', 'OpsWay1', 'Developer' ],
  [ "Alexander Gornov",       69,   'algor', 'OpsWay3', 'Developer' ],
  [ "Sergey Gorchakov",       52,   'segor', 'OpsWay1', 'Manager' ]
]

user_list.each do |name, rate, login, team, role|
  User.create( name: name, daily_rate: rate, login: login, team: Team.find_by_name(team), role: Role.find_by_name(role) )
end

role_list = %W(Manager Developer)

team_list = ['OpsWay1', 'OpsWay2', 'OpsWay3']
user_list = [
  [ "Dev1", 50,   'dev1', 'OpsWay1', 'Developer' ],
  [ "Dev2", 60,   'dev2', 'OpsWay2', 'Developer' ],
  [ "Dev3", 70,   'dev3', 'OpsWay3', 'Developer' ],
  [ "Dev4", 80,   'dev4', 'OpsWay3', 'Developer' ],
  [ "Dev5", 80,   'dev5', 'OpsWay2', 'Developer' ],
  [ "Dev6", 40,   'dev6', 'OpsWay1', 'Developer' ]


]

role_list.each {|name| Role.create( name: name) }
team_list.each {|name| Team.create( name: name) }

user_list.each do |name, rate, login, team, role|
  User.create( name: name, daily_rate: rate, login: login, team: Team.find_by_name(team), role: Role.find_by_name(role) )
end

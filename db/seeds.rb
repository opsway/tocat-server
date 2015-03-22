role_list = %W(Manager Developer)

if Rails.env.test?
  team_list = ['OpsWay1', 'OpsWay2', 'OpsWay3']
  user_list = [
    [ "Dev1", 50,   'dev1', 'OpsWay1', 'Developer' ],
    [ "Dev2", 60,   'dev2', 'OpsWay2', 'Developer' ],
    [ "Dev3", 70,   'dev3', 'OpsWay3', 'Developer' ],
    [ "Dev4", 80,   'dev4', 'OpsWay3', 'Developer' ]
  ]
else
  team_list = ['OpsWay1', 'OpsWay2', 'OpsWay3', 'OpsWay4', 'OpsWay5', 'Central Office']
  user_list = [
    [ "Dmitriy Ivanenko",       62,   'dmiva',          'OpsWay1', 'Developer' ],
    [ "Aleksandr Ishchenko",    27,   'altis',          'OpsWay1', 'Developer' ],
    [ "Volodymir Rudakov",      38,   'vorud',          'OpsWay2', 'Developer' ],
    [ "Stanislav Derebcinschi", 52,   'stder',          'OpsWay2', 'Developer' ],
    [ "Yuriy Kobrynyuk",        39,   'yukob',          'OpsWay2', 'Developer' ],
    [ "Stanislav Pivovartsev",  67,   'stpiv',          'OpsWay2', 'Developer' ],
    [ "Oksana Melnik",          69,   'okmel',          'OpsWay2', 'Manager'   ],
    [ "Andrey Lebedinskiy",     78,   'anleb',          'OpsWay3', 'Manager'   ],
    [ "Sergiy Morin",            0,   'morin.sergey1',  'OpsWay2', 'Manager'   ],
    [ "Yurii Lunhol",           31,   'yulun',          'OpsWay2', 'Developer' ],
    [ "Ruslan Abdullaev",       62,   'ruabd',          'OpsWay2', 'Developer' ],
    [ "Nikita Kushnir",         52,   'nikus',          'OpsWay2', 'Developer' ],
    [ "Stas Morgun",            26,   'stmor',          'OpsWay3', 'Developer' ],
    [ "Peter Kurbatsky",        31,   'pekub',          'OpsWay4', 'Developer' ],
    [ "Max Voronov",            57,   'mavor',          'OpsWay1', 'Developer' ],
    [ "Dmitrii Mikhailov",      49,   'dimih',          'OpsWay1', 'Developer' ],
    [ "Andriy Zherebchenko",    98,   'anzhe',          'OpsWay1', 'Developer' ],
    [ "Alexandr Vronskiy",      104,  'alvro',          'OpsWay1', 'Developer' ],
    [ "Alexander Dmitrienko",   72,   'aldmi',          'OpsWay1', 'Developer' ],
    [ "Alexander Gornov",       69,   'algor',          'OpsWay3', 'Developer' ],
    [ "Sergey Gorchakov",       52,   'segor',          'OpsWay1', 'Manager'   ],
    [ "Andriy Samilyak",        00,   'verlgoff',       'OpsWay4', 'Manager'   ]

  ]
end
role_list.each {|name| Role.create( name: name) }
team_list.each {|name| Team.create( name: name) }

user_list.each do |name, rate, login, team, role|
  User.create( name: name, daily_rate: rate, login: login, team: Team.find_by_name(team), role: Role.find_by_name(role) )
end

config = require './config'
url = config.url

frisby.create('Correct User')
  .post url + '/users',
    user:
      name: 'TestUser'
      login: 'TestUser'
      active: true
      team: 1
      role: 2
      daily_rate: 55
  .expectStatus(201)
  .afterJSON (user)->
    frisby.create 'Make user inactive'
      .delete url + '/user/' + user.id
      .expectStatus 200
      .afterJSON (user)->
        frisby.create "Can't update inactive user" 
          .patch url + '/user/' + user.id,
            user:
              name: 'some another'
          .expectStatus(422)
          .expectJSON {errors: ['User is inactive']}
          .afterJSON ->
            frisby.create('Make user active back')
              .delete url + '/user/' + user.id 
              .expectStatus(200)
              .afterJSON (user)->
                expect(user.active).toBe true
                frisby.create('List of active users')
                  .get url + '/users'
                  .expectStatus(200)
                  .afterJSON (users)->
                    expect(users.length).toBe 11
                  .toss()
              .toss()
          .toss()
      .toss()
  .toss()

frisby.create('Can update name')
  .patch url + '/user/1',
    user:
      name: 'New Other Name1'
  .expectStatus 200
  .afterJSON (user)->
    frisby.create 'User have new name'
      .get url + '/user/1'
      .afterJSON (user)->
        expect(user.name == 'New Other Name1').toBe(true)
      .toss()
  .toss()

frisby.create('Can set role developer')
  .patch url + '/user/8',
    user:
      role: 2
  .expectStatus 200
  .afterJSON (user)->
    frisby.create 'User have new role'
      .get url + '/user/8'
      .afterJSON (user)->
        expect(user.role.id == 2).toBe(true)
      .toss()
  .toss()
frisby.create('Can update role')
  .patch url + '/user/1',
    user:
      role: 1
  .expectStatus 200
  .afterJSON (user)->
    frisby.create 'User have new role'
      .get url + '/user/1'
      .afterJSON (user)->
        expect(user.role.id == 1).toBe(true)
      .toss()
  .toss()

frisby.create('Can change team')
  .patch url + '/user/2',
    user:
      team: 1
  .expectStatus 200
  .afterJSON (user)->
    frisby.create 'User have new team'
      .get url + '/user/2'
      .afterJSON (user)->
        expect(user.team.id == 1).toBe(true)
      .toss()
  .toss()

frisby.create("Can remove manager from team")
  .patch url + '/user/9',
    user:
      role: 2
  .expectStatus(200)
  .toss()
frisby.create("Can't become manager in team with manager")
  .patch url + '/user/2',
    user:
      role: 1
  .expectStatus(406)
  .expectJSON {errors: ['Team already have a manager']}
  .afterJSON (user)->
    frisby.create("But can become manager in team without managers")
      .patch url + '/user/2',
        user:
          role: 1
          team: 2
      .expectStatus(200)
      .toss()
  .toss()

frisby.create('List of all users')
  .get url + '/users?anyuser=true'
  .expectStatus(200)
  .afterJSON (users)->
    expect(users.length).toBe 12
  .toss()

frisby.create('List of active users')
  .get url + '/users'
  .expectStatus(200)
  .afterJSON (users)->
    expect(users.length == 11).toBe true
  .toss()


var config = require('./config');
var url = config.url;


frisby.create('Correct invoice creation')
    .post(url + '/invoices',
      {
          "external_id": '67899000000303001' + Math.random()
      })
    .expectStatus(201)
    .toss();

frisby.create('Duplicate invoice creation')
    .post(url + '/invoices',
      {
          "external_id": '67899000000303001' + Math.random()
      })
    .expectStatus(422)
    .expectJSON({errors: ['ID is already used']})
    .toss();

frisby.create('Correct task creation')
    .post(url + '/tasks', {"external_id": "REDMINE-1021" + Math.random()})
	.expectStatus(201)
    .toss();

frisby.create('Duplicate task creation')
    .post(url + '/tasks', {"external_id": "REDMINE-1021" + Math.random()})
    .expectStatus(422)
    .expectJSON({errors: ['ID is already used']})
    .toss();
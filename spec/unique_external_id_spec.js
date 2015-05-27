var config = require('./config');
var url = config.url;

var invoice_id = '67899000000303001' + Math.random();
var task_id = "REDMINE-1021" + Math.random()


frisby.create('Correct invoice creation')
    .post(url + '/invoices',
      {
          "external_id": invoice_id
      })
    .expectStatus(201)
    .toss();

frisby.create('Duplicate invoice creation')
    .post(url + '/invoices',
      {
          "external_id": invoice_id
      })
    .expectStatus(422)
    .expectJSON({errors: ['External ID is already used']})
    .toss();

frisby.create('Correct task creation')
    .post(url + '/tasks', {"external_id": task_id})
	.expectStatus(201)
    .toss();

frisby.create('Duplicate task creation')
    .post(url + '/tasks', {"external_id": task_id})
    .expectStatus(422)
    .expectJSON({errors: ['External ID is already used']})
    .toss();

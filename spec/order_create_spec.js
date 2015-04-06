var config = require('./config');
var url = config.url;



frisby.create('Create Order: set allocatable budget more than invoiced')
    .post(url + '/orders',

    	{
          "invoiced_budget": 150.00,
          "allocatable_budget": 600.00,
          "name" : "Test",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
        }

        )
    .expectStatus(422)
    .expectJSON({errors: ['Allocatable budget is greater than invoiced budget']})
    .toss();


frisby.create('Create Order: set allocatable budget equal to invoiced')
    .post(url + '/orders',

    	{
          "invoiced_budget": 150.00,
          "allocatable_budget": 150.00,
          "name" : "Test",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
        }

        )
    .expectStatus(201)
    .toss();

frisby.create('Create Order: set allocatable budget less than zero')
    .post(url + '/orders',

    	{
          "invoiced_budget": 150.00,
          "allocatable_budget": -10,
          "name" : "Test",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
        }

        )
    .expectStatus(422)
    .expectJSON({errors:['Allocatable should be positive number']})
    .toss();

frisby.create('Create Order: set allocatable budget to zero')
    .post(url + '/orders',

    	{
          "invoiced_budget": 150.00,
          "allocatable_budget": 0,
          "name" : "Test",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
        }

        )
    .expectStatus(201)
    .toss();

frisby.create('Create Order: set invoiced budget less than zero')
    .post(url + '/orders',

    	{
          "invoiced_budget": -10,
          "allocatable_budget": -20,
          "name" : "Test",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
        }

        )
    .expectStatus(422)
    .expectJSON({errors:['Invoiced budget should be greater than 0']})
    .toss();


frisby.create('Create Order: name can not be empty')
    .post(url + '/orders',

    	{
          "invoiced_budget": 10,
          "allocatable_budget": 5,
          "name" : "",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
        }

        )
    .expectStatus(422)
    .expectJSON({errors:['Order name can not be empty']})
    .toss();

frisby.create('Create Order: check team exists')
    .post(url + '/orders',

    	{
          "invoiced_budget": 20,
          "allocatable_budget": 10,
          "name" : "Test order",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 999999999
          }
        }

        )
    .expectStatus(422)
    .expectJSON({errors:['Team does not exists']})
    .toss();

frisby.create('Correct order creation')
    .post(url + '/orders',

      {
          "invoiced_budget": 150.00,
          "allocatable_budget": 100.00,
          "name" : "Test",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
        }

        )
    .expectStatus(201)
    .afterJSON(function(order) {
      frisby.create("Check free budget upon order creation")
        .get(url + '/order/' + order.id)
        .expectStatus(200)
        .expectJSON({'free_budget' : 100})
        .toss();

      frisby.create('Update order with correct allocatable budget')
        .patch(url + '/order/' + order.id, {allocatable_budget: 120})
        .expectStatus(200)
        .toss();

      frisby.create("Free budget should increase when allocatable budget increases")
        .get(url + '/order/' + order.id)
        .expectStatus(200)
        .expectJSON({'free_budget' : 120})
        .toss();

      frisby.create('Update order with correct decreased allocatable budget')
        .patch(url + '/order/' + order.id, {allocatable_budget: 50})
        .expectStatus(200)
        .toss();

      frisby.create("Free budget should decrease when allocatable budget decreases")
        .get(url + '/order/' + order.id)
        .expectStatus(200)
        .expectJSON({'free_budget' : 50})
        .toss();


      frisby.create('Update order with allocatable budget greater than invoiced')
        .patch(url + '/order/' + order.id, {allocatable_budget: 200})
        .expectStatus(422)
        .expectJSON({errors:['Allocatable budget is greater than invoiced budget']})
        .toss();

      frisby.create('Update order with allocatable budget less than zero')
        .patch(url + '/order/' + order.id, {allocatable_budget: -10})
        .expectStatus(422)
        .expectJSON({errors:['Allocatable should be positive number']})
        .toss();

      frisby.create('Update order with invoiced budget less than zero')
        .patch(url + '/order/' + order.id, {invoiced_budget: -10})
        .expectStatus(422)
        .expectJSON({errors:['Invoiced budget should be greater than 0']})
        .toss();

      frisby.create('Update order with invoiced budget set to zero')
        .patch(url + '/order/' + order.id, {invoiced_budget: 0})
        .expectStatus(422)
        .expectJSON({errors:['Invoiced budget should be greater than 0']})
        .toss();

      })
    .toss();

var frisby = require('frisby');
var url = 'http://private-bc12f-tocat.apiary-mock.com';

frisby.create('Create Order: set allocatable budget more than invoiced')
    .post(url + '/order', 

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
    .expectStatus(402)
    .expectJSON({error:'ORDER_VALIDATION_FAILED'})
    .expectBodyContains('Allocatable budget should be less or equal')
    .toss();

frisby.create('Create Order: set allocatable budget equal to invoiced')
    .post(url + '/order', 

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

frisby.create('Create Order: set allocatable budget less then zero')
    .post(url + '/order', 

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
    .expectStatus(402)
    .expectJSON({error:'ORDER_VALIDATION_FAILED'})
    .expectBodyContains('Allocatable budget should be less or equal')
    .toss();  

frisby.create('Create Order: set allocatable budget to zero')
    .post(url + '/order', 

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
    .expectStatus(402)
    .expectJSON({error:'ORDER_VALIDATION_FAILED'})
    .expectBodyContains('Allocatable budget should be less or equal')
    .toss();    

frisby.create('Create Order: set invoiced budget less then zero')
    .post(url + '/order', 

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
    .expectStatus(402)
    .expectJSON({error:'ORDER_VALIDATION_FAILED'})
    .expectBodyContains('Allocatable budget should be less or equal')
    .toss();  


frisby.create('Create Order: name can not be empty')
    .post(url + '/order', 

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
    .expectStatus(402)
    .expectJSON({error:'ORDER_VALIDATION_FAILED'})
    .expectBodyContains('Order name can not be empty')
    .toss(); 

frisby.create('Create Order: check team exists')
    .post(url + '/order', 

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
    .expectStatus(402)
    .expectJSON({error:'ORDER_VALIDATION_FAILED'})
    .expectBodyContains('Team does not exists')
    .toss();  

frisby.create('Correct order creation')
    .post(url + '/order', 

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
      frisby.create('Update order with correct allocatable budget')
        .patch(url + '/order/' + order.id, {allocatable_budget: 120})
        .expectStatus(201)
        .toss();

      frisby.create('Update order with allocatable budget greater than invoiced')
        .patch(url + '/order/' + order.id, {allocatable_budget: 200})
        .expectStatus(402)
        .expectJSON({error:'ORDER_VALIDATION_FAILED'})
        .toss();

      frisby.create('Update order with allocatable budget less than zero')
        .patch(url + '/order/' + order.id, {allocatable_budget: -10})
        .expectStatus(402)
        .expectJSON({error:'ORDER_VALIDATION_FAILED'})
        .toss();

      frisby.create('Update order with invoiced budget less than zero')
        .patch(url + '/order/' + order.id, {invoiced_budget: -10})
        .expectStatus(402)
        .expectJSON({error:'ORDER_VALIDATION_FAILED'})
        .toss();

      frisby.create('Update order with invoiced budget set to zero')
        .patch(url + '/order/' + order.id, {invoiced_budget: 0})
        .expectStatus(402)
        .expectJSON({error:'ORDER_VALIDATION_FAILED'})
        .toss();

      })
    .toss(); 
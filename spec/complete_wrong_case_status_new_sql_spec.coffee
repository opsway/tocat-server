config = require './config'
url = config.url

frisby.create 'Correct invoice' 
  .post url + '/invoices',
    "external_id": Math.floor(Math.random() * (99999 - 1)) + 30
  .expectStatus(201)
  .afterJSON (invoice)->
      frisby.create('Correct order creation')
          .post url + '/orders',
            "invoiced_budget": 150.00,
            "allocatable_budget": 100.00,
            "name" : "Test",
            "description" : "This is just a test order for SuperClient",
            "team":  
              "id" : 1
          .expectStatus(201)
          .afterJSON (order)->
              frisby.create("Can't complete order when status errors present")
                  .post(url + '/order/' + order.id + '/complete/')
                  .expectStatus(422)
                  .expectJSON({errors: ['TOCAT Self-check has errors, please check Status page']})
                  .toss()
          .toss()
  .toss()

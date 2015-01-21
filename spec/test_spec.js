var frisby = require('frisby');
var url = 'http://tocat.opsway.com';

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
    .expectStatus(422)
    .expectJSON({error:'ORDER_ERROR'})
    .expectBodyContains('Allocatable budget should be less or equal')
    .afterJSON(function(msg) {
      frisby.create('Invoiced budget should be equal to allocatable')
            .get(url + '/order/' + msg.id)
            .expectStatus(200)
            .expectJSON({'invoiced_budget' : 50, 'free_budget' : 50, 'parent_order' : {'id' : msg.id, "href" : "/order/" + msg.id}})
            .toss()
      })
    .toss();
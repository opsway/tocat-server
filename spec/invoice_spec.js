//Can not link to order already paid invoice ?????


var frisby = require('frisby');
var url = 'http://tocat.opsway.com';


frisby.create('Correct invoice')
    .post(url + '/invoice',

        {
          "external_id": '67899000000303002'
        }
    .expectStatus(201)
    .afterJSON(function(invoice){
      frisby.create('Delete invoice')
            .delete(url + '/invoice/' + invoice.id)
            .expectStatus(200)
            .toss();
    })
    .toss()


frisby.create('Correct invoice')
    .post(url + '/invoice',
        {
          "external_id": '67899000000303001'
        }
    .expectStatus(201)
    .afterJSON(function(invoice){
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
          })
        .expectStatus(201)
        .afterJSON(function(order){
          frisby.create('Invoice order with inexistent invoice')
            .post(url + '/order/' + order.id + /invoice, {'id' : 99999999})
            .expectStatus(422)
            .expectJSON({error:'ORDER_ERROR'})
            .expectBodyContains('Invoice does not exist')
            .toss();

          frisby.create('Invoice order with inexistent invoice')
            .post(url + '/order/' + order.id + /invoice, {'id' : invoice.id})
            .expectStatus(200)
            .toss();

          frisby.create('Delete used invoice is not allowed')
            .delete(url + '/invoice/' + invoice.id)
            .expectStatus(422)
            .expectJSON({error:'ORDER_ERROR'})
            .expectBodyContains('Invoice is linked to orders')
            .toss();

          frisby.create('Create correct suborder')
            .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 50, 'team' : {'id' : 2}, 'name' : 'super order'})
            .expectStatus(201)
            .afterJSON(function(subOrder) {
              frisby.create('Create second correct suborder for the same team as parent order')
                .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 30, 'team' : {'id' : 1}, 'name' : 'super order'})
                .expectStatus(201)
                .afterJSON(function(subOrder2) {
                   frisby.create('Correct task creation')
                    .post(url + '/task', {"external_id": "TST-102" })
                    .expectStatus(201)
                      .afterJSON(function(task){
                        frisby.create('Set task budgets')
                          .post(url + '/task/' + task.id + '/budget', {'budget' : [
                              {
                                'order_id' : order.id,
                                'budget'   : 30
                              },
                              {
                                'order_id' : subOrder2.id,
                                'budget'   : 20
                              }
                            ]})
                          .expectStatus(200)
                          .afterJSON(function(){

                            ///TEST PAID on invoice

                          })
                          .toss();
                })
                .toss();
            .toss();              
            })
            .toss();
        })
        .toss();
    })
    .toss();
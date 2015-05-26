var config = require('./config');
var url = config.url;


frisby.create('Correct invoice')
    .post(url + '/invoices',
    {
        "external_id": Math.floor(Math.random() * (99999 - 1)) + 30
    })
    .expectStatus(201)
    .afterJSON(function(invoice){

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
            })
            .expectStatus(201)
            .afterJSON(function(order){

              frisby.create('Invoice order with correct invoice')
                .post(url + '/order/' + order.id + '/invoice', {'invoice_id' : invoice.id})
                .expectStatus(200)
                .toss();

              frisby.create('Set invoice paid')
                .post(url + '/invoice/' + invoice.id + '/paid')
                .expectStatus(200)
                .toss();

              frisby.create('Create suborder from paid order')
                .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 20, 'team' : {'id' : 2}, 'name' : 'super order'})
                .expectStatus(201)
                .afterJSON(function(subOrder) {

                    frisby.create('Check that suborder from paid order is paid')
                        .get(url + '/order/' + subOrder.id)
                        .expectStatus(200)
                        .expectJSON({'paid' : true})
                        .toss();

                    frisby.create('Decrease suborder budgets')
                        .patch(url + '/order/' + subOrder.id, {'allocatable_budget': 10, 'invoiced_budget' : 10})
                        .expectStatus(200)
                        .afterJSON(function(){
                          frisby.create('Allocatable budget on parent order should NOT increase, free budget should increase')
                            .get(url + '/order/' + order.id)
                            .expectStatus(200)
                            .expectJSON({'allocatable_budget' : 100, 'free_budget' : 90})
                            .toss()
                        })
                        .toss();

                })
                .toss();
            })
            .toss();
    })
    .toss();

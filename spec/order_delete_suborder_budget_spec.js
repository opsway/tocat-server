var config = require('./config');
var url = config.url;

frisby.create('Correct invoice')
    .post(url + '/invoices',
    {
        "external_id": '67899000000303015'
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

              frisby.create('Create suborder from order')
                .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 20, 'team' : {'id' : 2}, 'name' : 'super order'})
                .expectStatus(201)
                .afterJSON(function(subOrder){

                    frisby.create("Free budget should be calculated taking into consideration suborders and tasks budgets")
                        .get(url + '/order/' + order.id)
                        .expectStatus(200)
                        .expectJSON({'free_budget' : 80})
                        .toss();

                    frisby.create("Delete suborder")
                        .delete(url + '/order/' + subOrder.id)
                        .expectStatus(200)
                        .toss();

                    frisby.create("Free budget should be increased after suborder is deleted")
                        .get(url + '/order/' + order.id)
                        .expectStatus(200)
                        .expectJSON({'free_budget' : 100})
                        .toss();

                })
                .toss();

            })
            .toss();
    })
    .toss();
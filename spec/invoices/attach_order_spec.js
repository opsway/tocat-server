var config = require('./../config');
var url = config.url;

frisby.create('Correct invoice')
    .post(url + '/invoices',
    {
        "external_id": Math.floor(Math.random() * (99999 - 1)) + 30
    })
    .expectStatus(201)
    .afterJSON(function(invoice){
        frisby.create('Create internal order')
            .post(
            url + '/orders',
            {
                "internal_order": true,
                "invoiced_budget": 100.00,
                "allocatable_budget": 60.00,
                "name" : "Test",
                "description" : "This is just a test order for SuperClient",
                "team":  { "id" : 1 }
            }
            )
            .expectStatus(201)
            .afterJSON(function(order) {
                frisby.create('Attach internal order to invoice should fail')
                    .post(url + '/order/' + order.id + '/invoice',
                    {
                        invoice_id: invoice.id
                    }
                    )
                    .expectStatus(422)
                    .expectJSON({errors: ["Internal order can't have invoice"]})
                    .toss();
            }).toss();
    })
    .toss();
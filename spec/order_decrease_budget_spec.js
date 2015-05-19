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

              frisby.create('Create suborder from order')
                .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 20, 'team' : {'id' : 2}, 'name' : 'super order'})
                .expectStatus(201)
                .toss();

              frisby.create('Update order with allocatable budget less than used from order')
                .patch(url + '/order/' + order.id, {'allocatable_budget': 10, 'invoiced_budget': 10})
                .expectStatus(422)
                .expectJSON({errors:['Allocatable bugdet is less than already used from order']})
                .toss();

              frisby.create('Update order with allocatable budget less than used from order')
                .patch(url + '/order/' + order.id, {'allocatable_budget': 10, 'invoiced_budget': 100})
                .expectStatus(422)
                .expectJSON({errors:['Allocatable bugdet is less than already used from order']})
                .toss();

              frisby.create('Update order with allocatable budget as already used from order')
                .patch(url + '/order/' + order.id, {'allocatable_budget': 20, 'invoiced_budget': 100})
                .expectStatus(200)
                .toss();

            })
            .toss();
    })
    .toss();

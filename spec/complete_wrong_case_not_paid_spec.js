var config = require('./config');
var url = config.url;

var task1_ext_id = Math.floor(Math.random() * (99999 - 1)) + 30;


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
                  "id" : 2
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

            frisby.create('Check that order is paid')
                .get(url + '/order/' + order.id)
                .expectStatus(200)
                .expectJSON({'paid' : true})
                .toss();

              frisby.create('Correct order2 creation')
                .post(url + '/orders',
                {
                    "invoiced_budget": 150.00,
                    "allocatable_budget": 100.00,
                    "name" : "Test",
                    "description" : "This is just a test order for SuperClient",
                    "team":  {
                      "id" : 2
                    }
                })
                .expectStatus(201)
                .afterJSON(function(order2){

                    frisby.create('Check that order2 is NOT paid')
                        .get(url + '/order/' + order2.id)
                        .expectStatus(200)
                        .expectJSON({'paid' : false})
                        .toss();

                    frisby.create('Correct task creation')
                        .post(url + '/tasks', {"external_id": task1_ext_id })
                        .expectStatus(201)
                        .afterJSON(function(task1){

                            frisby.create('Set task1 budgets')
                                .post(url + '/task/' + task1.id + '/budget', {'budget' : [
                                    {
                                        'order_id' : order.id,
                                        'budget'   : 30
                                    },
                                    {
                                        'order_id' : order2.id,
                                        'budget'   : 50
                                    }

                                ]})
                                .expectStatus(200)
                                .toss();


                            frisby.create('Task1 is not paid, but it is accepted #1')
                                        .get(url + '/task/' + task1.id)
                                        .expectStatus(200)
                                        .expectJSON({'paid' : false, 'accepted' : false })
                                        .toss();

                            frisby.create('Set task Resolver id=2')
                                .post(url + '/task/' + task1.id + '/resolver', {'user_id' : 2})
                                .expectStatus(200)
                                .toss();

                            frisby.create('Set task1 accepted')
                                        .post(url + '/task/' + task1.id + '/accept')
                                        .expectStatus(200)
                                        .toss();

                            frisby.create('Correct task creation')
                                .post(url + '/tasks', {"external_id": Math.floor(Math.random() * (99999 - 1)) + 30 })
                                .expectStatus(201)
                                .afterJSON(function(task2){

                                    frisby.create('Set task2 budgets')
                                        .post(url + '/task/' + task2.id + '/budget', {'budget' : [
                                            {
                                                'order_id' : order.id,
                                                'budget'   : 10
                                            }
                                        ]})
                                        .expectStatus(200)
                                        .toss();

                                    frisby.create('Set task2 accepted')
                                        .post(url + '/task/' + task2.id + '/accept')
                                        .expectStatus(200)
                                        .toss();


                                    frisby.create('Task1 is not paid, but it is accepted #2')
                                        .get(url + '/task/' + task1.id)
                                        .expectStatus(200)
                                        .expectJSON({'paid' : false, 'accepted' : true })
                                        .toss();

                                    frisby.create('Task2 is Accepted&Paid')
                                        .get(url + '/task/' + task2.id)
                                        .expectStatus(200)
                                        .expectJSON({'paid' : true, 'accepted' : true })
                                        .toss();

                                    frisby.create('Can not complete order with un-paid tasks')
                                        .post(url + '/order/' + order.id + '/complete/')
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not complete order: task(s) ' + task1_ext_id + ' not Accepted&Paid']})
                                        .toss();

                                    frisby.create('Correct invoice2')
                                        .post(url + '/invoices',
                                        {
                                            "external_id": Math.floor(Math.random() * (99999 - 1)) + 30
                                        })
                                        .expectStatus(201)
                                        .afterJSON(function(invoice2){


                                            frisby.create('Invoice order2 with correct invoice2')
                                                .post(url + '/order/' + order2.id + '/invoice', {'invoice_id' : invoice2.id})
                                                .expectStatus(200)
                                                .toss();

                                            frisby.create('Set invoice2 paid')
                                                .post(url + '/invoice/' + invoice2.id + '/paid')
                                                .expectStatus(200)
                                                .toss();

                                            frisby.create('Can complete order1')
                                                .post(url + '/order/' + order.id + '/complete/')
                                                .expectStatus(200)
                                                .toss();

                                            frisby.create('Can complete order2')
                                                .post(url + '/order/' + order2.id + '/complete/')
                                                .expectStatus(200)
                                                .toss();

                                            frisby.create('Check that order is set completed')
                                                .get(url + '/order/' + order.id)
                                                .expectStatus(200)
                                                .expectJSON({'completed' : true })
                                                .toss();


                                })
                                .toss();
                            })
                            .toss();
                        })
                        .toss();
                    })
                    .toss();
            })
            .toss();
})
.toss();

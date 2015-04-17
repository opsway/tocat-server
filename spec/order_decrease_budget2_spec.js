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

                  frisby.create('Correct task creation')
                    .post(url + '/tasks', {"external_id": "TST-101" })
                    .expectStatus(201)
                    .afterJSON(function(task){

                      frisby.create('Set task budgets')
                        .post(url + '/task/' + task.id + '/budget', {'budget' : [
                          {
                            'order_id' : order.id,
                            'budget'   : 30
                          }
                        ]})
                        .expectStatus(200)
                        .toss();

                      frisby.create('Update order with allocatable budget less than used from order')
                        .patch(url + '/order/' + order.id, {'allocatable_budget': 40, 'invoiced_budget': 40})
                        .expectStatus(422)
                        .expectJSON({errors:['Allocatable bugdet is less than already used from order']})
                        .toss();

                      frisby.create('Update order with allocatable budget less than used from order')
                        .patch(url + '/order/' + order.id, {'allocatable_budget': 40, 'invoiced_budget': 100})
                        .expectStatus(422)
                        .expectJSON({errors:['Allocatable bugdet is less than already used from order']})
                        .toss();

                      frisby.create('Update order with allocatable budget as already used from order')
                        .patch(url + '/order/' + order.id, {'allocatable_budget': 50, 'invoiced_budget': 50})
                        .expectStatus(200)
                        .toss();

                      frisby.create("Free budget should be calculated taking into consideration suborders and tasks budgets")
                        .get(url + '/order/' + order.id)
                        .expectStatus(200)
                        .expectJSON({'free_budget' : 0})
                        .toss();

                      frisby.create('Update order with allocatable budget to have small free budget')
                        .patch(url + '/order/' + order.id, {'allocatable_budget': 60, 'invoiced_budget': 80})
                        .expectStatus(200)
                        .toss();

                      frisby.create("Free budget should be calculated taking into consideration suborders and tasks budgets")
                        .get(url + '/order/' + order.id)
                        .expectStatus(200)
                        .expectJSON({'free_budget' : 10})
                        .toss();

                      frisby.create('Set task budgets')
                        .post(url + '/task/' + task.id + '/budget', {'budget' : [
                          {
                            'order_id' : order.id,
                            'budget'   : 40
                          }
                        ]})
                        .expectStatus(200)
                        .toss();

                      frisby.create("Free budget should be calculated taking into consideration suborders and tasks budgets")
                        .get(url + '/order/' + order.id)
                        .expectStatus(200)
                        .expectJSON({'free_budget' : 0})
                        .toss();

                      frisby.create('Update order with more allocatable budget')
                        .patch(url + '/order/' + order.id, {'allocatable_budget': 80, 'invoiced_budget': 80})
                        .expectStatus(200)
                        .toss();

                      frisby.create("Free budget should be calculated taking into consideration suborders and tasks budgets")
                        .get(url + '/order/' + order.id)
                        .expectStatus(200)
                        .expectJSON({'free_budget' : 20})
                        .toss();

                      frisby.create('Update suborder with more allocatable budget')
                        .patch(url + '/order/' + subOrder.id, {'invoiced_budget': 30, 'allocatable_budget': 30 })
                        .expectStatus(200)
                        .inspectBody()
                        .toss();

                      frisby.create("Free budget should be calculated taking into consideration suborders and tasks budgets")
                        .get(url + '/order/' + order.id)
                        .expectStatus(200)
                        .expectJSON({'free_budget' : 10})
                        .toss();

                      frisby.create('Correct task creation')
                        .post(url + '/tasks', {"external_id": "TST-102" })
                        .expectStatus(201)
                        .afterJSON(function(task2){

                          frisby.create('Set task budgets')
                            .post(url + '/task/' + task2.id + '/budget', {'budget' : [
                              {
                                'order_id' : subOrder.id,
                                'budget'   : 10
                              }
                            ]})
                            .expectStatus(200)
                            .toss();

                          frisby.create("Free budget should NOT take into consideration tasks of suborders")
                            .get(url + '/order/' + order.id)
                            .expectStatus(200)
                            .expectJSON({'free_budget' : 0})
                            .toss(); 

                        })
                        .toss();

                    })
                    .toss()


                })
                .toss();


            })
            .toss();
    })
    .toss();
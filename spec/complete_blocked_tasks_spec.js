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

              frisby.create('Check that order is paid')
                .get(url + '/order/' + order.id)
                .expectStatus(200)
                .expectJSON({'paid' : true})
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

                    frisby.create('Correct task creation')
                        .post(url + '/tasks', {"external_id": Math.floor(Math.random() * (99999 - 1)) + 30 })
                        .expectStatus(201)
                        .afterJSON(function(task1){

                            frisby.create('Set task budgets')
                                .post(url + '/task/' + task1.id + '/budget', {'budget' : [
                                    {
                                        'order_id' : order.id,
                                        'budget'   : 30
                                    }
                                ]})
                                .expectStatus(200)
                                .toss();

                            frisby.create('Set task Resolver id=1')
                                .post(url + '/task/' + task1.id + '/resolver', {'user_id' : 1})
                                .expectStatus(200)
                                .toss();

                            frisby.create('Correct task creation')
                                .post(url + '/tasks', {"external_id": Math.floor(Math.random() * (99999 - 1)) + 30 })
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

                                    frisby.create('Set task1 accepted')
                                        .post(url + '/task/' + task1.id + '/accept')
                                        .expectStatus(200)
                                        .toss();

                                    frisby.create('Set task2 accepted')
                                        .post(url + '/task/' + task2.id + '/accept')
                                        .expectStatus(200)
                                        .toss();

                                    frisby.create('Can complete parent order')
                                        .post(url + '/order/' + order.id + '/complete')
                                        .expectStatus(200)
                                        .toss();


                                    frisby.create('Should not be able to increase task1 budget')
                                        .post(url + '/task/' + task1.id + '/budget', {'budget' : [
                                            {
                                                'order_id' : order.id,
                                                'budget'   : 40
                                            }
                                        ]})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not update budget for task that is Accepted and paid']})
                                        .toss();

                                    frisby.create('Should not be able to decrease task1 budget')
                                        .post(url + '/task/' + task1.id + '/budget', {'budget' : [
                                            {
                                                'order_id' : order.id,
                                                'budget'   : 10
                                            }
                                        ]})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not update budget for task that is Accepted and paid']})
                                        .toss();

                                    frisby.create('Should not be able to remove task1 budget')
                                        .post(url + '/task/' + task1.id + '/budget', {'budget' : [
                                            {
                                            }
                                        ]})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not update budget for task that is Accepted and paid']})
                                        .toss();

                                    frisby.create('Should not be able to increase task2 budget')
                                        .post(url + '/task/' + task2.id + '/budget', {'budget' : [
                                            {
                                                'order_id' : subOrder.id,
                                                'budget'   : 40
                                            }
                                        ]})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not update budget for task that is Accepted and paid']})
                                        .toss();

                                    frisby.create('Should not be able to decrease task2 budget')
                                        .post(url + '/task/' + task2.id + '/budget', {'budget' : [
                                            {
                                                'order_id' : subOrder.id,
                                                'budget'   : 10
                                            }
                                        ]})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not update budget for task that is Accepted and paid']})
                                        .toss();

                                    frisby.create('Should not be able to remove task2 budget')
                                        .post(url + '/task/' + task2.id + '/budget', {'budget' : [
                                            {
                                            }
                                        ]})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not update budget for task that is Accepted and paid']})
                                        .toss();

                                    frisby.create('Correct task3 creation')
                                        .post(url + '/tasks', {"external_id": "REDMINE-1021" })
                                        .expectStatus(201)
                                        .afterJSON(function(task1){

                                            frisby.create('Should not be able to use completed order in new budgets')
                                                .post(url + '/task/' + task1.id + '/budget', {'budget' : [
                                                    {
                                                        'order_id' : order.id,
                                                        'budget'   : 10
                                                    }
                                                ]})
                                                .expectStatus(422)
                                                .expectJSON({errors:['Completed order is used in budgets, can not update task']})
                                                .toss();

                                            frisby.create('Should be able to modify review requested flag')
                                                .post(url + '/task/' + task1.id + '/review')
                                                .expectStatus(200)
                                                .toss();
                                        })
                                        .toss();

                                    frisby.create('Change resolver in task1 should not be possible')
                                        .post(url + '/task/' + task1.id + '/resolver', {'user_id' : 6})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Completed order is used in budgets, can not update task']})
                                        .toss();

                                    frisby.create('Remove resolver in task1 should not be possible')
                                        .delete(url + '/task/' + task1.id + '/resolver')
                                        .expectStatus(422)
                                        .expectJSON({errors:['Completed order is used in budgets, can not update task']})
                                        .toss();

                                    frisby.create('Set resolver in task2 should not be possible')
                                        .post(url + '/task/' + task2.id + '/resolver', {'user_id' : 2})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Completed order is used in budgets, can not update task']})
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

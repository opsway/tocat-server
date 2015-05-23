var config = require('./config');
var url = config.url;

var task1_ext_id = Math.floor(Math.random() * (99999 - 1)) + 30
var task2_ext_id = Math.floor(Math.random() * (99999 - 1)) + 30

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

			  frisby.create('Can not un-complete order, that is not completed')
               	.delete(url + '/order/' + order.id + '/complete/')
               	.expectStatus(422)
               	.expectJSON({errors:['Can not un-complete order, that is not completed']})
               	.toss();

			  frisby.create('Can not complete unpaid order')
               	.post(url + '/order/' + order.id + '/complete/')
               	.expectStatus(422)
               	.expectJSON({errors:['Can not complete unpaid order']})
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

                    frisby.create('Can not complete suborder')
                        .post(url + '/order/' + subOrder.id + '/complete/')
                        .expectStatus(422)
                        .expectJSON({errors:['Can not complete suborder']})
                        .toss();

                    frisby.create('Correct task creation')
                        .post(url + '/tasks', {"external_id": task1_ext_id })
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
                                .post(url + '/tasks', {"external_id": task2_ext_id })
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

                                    frisby.create('Can not complete order with un-accepted tasks')
                                        .post(url + '/order/' + order.id + '/complete/')
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not complete order: task(s) ' + task1_ext_id + ',' + task2_ext_id + ' not Accepted&Paid']})
                                        .toss();

                                    frisby.create('Set task1 accepted')
                                        .post(url + '/task/' + task1.id + '/accept')
                                        .expectStatus(200)
                                        .toss();

                                    frisby.create('Can not complete order with un-accepted tasks')
                                        .post(url + '/order/' + order.id + '/complete/')
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not complete order: task(s) ' + task2_ext_id + ' not Accepted&Paid']})
                                        .toss();

                                    frisby.create('Set task2 accepted')
                                        .post(url + '/task/' + task2.id + '/accept')
                                        .expectStatus(200)
                                        .toss();


                                    frisby.create('Can complete parent order')
                                        .post(url + '/order/' + order.id + '/complete/')
                                        .expectStatus(200)
                                        .toss();


                                    frisby.create('Check that order is set completed')
                                        .get(url + '/order/' + order.id)
                                        .expectStatus(200)
                                        .expectJSON({'completed' : true })
                                        .toss();

                                    frisby.create('Can not create suborder from completed order')
                                        .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 20, 'team' : {'id' : 2}, 'name' : 'super order'})
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not create suborder from completed order']})
                                        .toss();

                                    frisby.create('Check that suborder is already set completed')
                                        .get(url + '/order/' + subOrder.id)
                                        .expectStatus(200)
                                        .expectJSON({'completed' : true })
                                        .toss();

                                    frisby.create('Can not delete suborder when parent order completed')
                                        .delete(url + '/order/' + subOrder.id)
                                        .expectStatus(422)
                                        .expectJSON({errors:['You can not delete order that is used in task budgeting']})
                                        .toss();

                                    frisby.create('Can not un-complete suborder')
                                        .delete(url + '/order/' + subOrder.id + '/complete/')
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not un-complete suborder']})
                                        .toss();

                                    frisby.create('Can not complete parent order twice')
                                        .post(url + '/order/' + order.id + '/complete/')
                                        .expectStatus(422)
                                        .expectJSON({errors:['Can not complete already completed order']})
                                        .toss();

                                    frisby.create('Correctly uncomplete order')
                                        .delete(url + '/order/' + order.id + '/complete/')
                                        .expectStatus(200)
                                        .toss();

                                    frisby.create('Check that order is set un-completed')
                                        .get(url + '/order/' + order.id)
                                        .expectStatus(200)
                                        .expectJSON({'completed' : false })
                                        .toss();

                                    frisby.create('Check that suborder is already set un-completed')
                                        .get(url + '/order/' + subOrder.id)
                                        .expectStatus(200)
                                        .expectJSON({'completed' : false })
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

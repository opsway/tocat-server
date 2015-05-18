var config = require('./config');
var url = config.url;


frisby.create('Correct invoice creation')
    .post(url + '/invoices',
      {
          "external_id": '67899000000303001'
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

            frisby.create('Correct task creation')
                .post(url + '/tasks', {"external_id": "REDMINE-1021" + Math.random() })
				.expectStatus(201)
                .afterJSON(function(task){

		            frisby.create('Set task budgets')
		                .post(url + '/task/' + task.id + '/budget', {'budget' : [
			                {
			                    'order_id' : order.id,
			                    'budget'   : 32
			                }
		                ]})
		                .expectStatus(200)
		                .toss();

						frisby.create('Set task accepted')
                        	.post(url + '/task/' + task.id + '/accept')
                        	.expectStatus(200)
                        	.toss();

						frisby.create('Set invoice as paid')
               				.post(url + '/invoice/' + invoice.id + '/paid')
               				.expectStatus(200)
               				.toss();

                        frisby.create('Set task Resolver id=2')
						    .post(url + '/task/' + task.id + '/resolver', {'user_id' : 2})
						    .expectStatus(200)
						    .toss();

                        frisby.create('Remove accepted flag from task')
                            .delete(url + '/invoice/' + invoice.id + '/paid')
                            .expectStatus(200)
                            .toss();

                        frisby.create('Expecting task NOT to be paid')
                            .get(url + '/task/' + task.id)
                            .expectStatus(200)
                            .inspectBody()
                            .expectJSON({'budget' : 32, 'paid' : false, 'accepted' : false})
                            .toss();

                        frisby.create('Create another un-paid order')
                            .post(url + '/orders',
                            {
                                "invoiced_budget": 100.00,
                                "allocatable_budget": 100.00,
                                "name" : "Test2",
                                "description" : "This is just a test order for SuperClient",
                                "team":  {
                                    "id" : 2
                                }
                            })
                            .expectStatus(201)
                            .afterJSON(function(order2){
                                frisby.create('Budget from un-paid order')
                                    .post(url + '/task/' + task.id + '/budget', {'budget' : [
                                    {
                                        'order_id' : order2.id,
                                        'budget'   : 32
                                    }
                                ]})
                                .expectStatus(200)
                                .toss();

                                frisby.create('Expecting task NOT to be paid')
                                    .get(url + '/task/' + task.id)
                                    .expectStatus(200)
                                    .expectJSON({'budget' : 32, 'paid' : false, 'accepted' : false})
                                    .toss();
                            })
                            .toss();
            	})
            	.toss();
        })
        .toss();
    })
	.toss();

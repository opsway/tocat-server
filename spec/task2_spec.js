var config = require('./config');
var url = config.url;


frisby.create('Correct invoice creation')
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

            frisby.create('Correct task creation')
                .post(url + '/tasks', {"external_id": Math.floor(Math.random() * (99999 - 1)) + 30 })
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


						frisby.create('Can not update budget for task that is Accepted and paid')
		                    .post(url + '/task/' + task.id + '/budget', {'budget' : [
		                      {
		                        'order_id' : order.id,
		                        'budget'   : 31
		                      }]})
		                    .expectStatus(422)
                    		.expectJSON({errors: ['Can not update budget for task that is Accepted and paid']})
                    		.toss();

                        frisby.create('Can not update budget for task that is Accepted and paid')
                            .post(url + '/task/' + task.id + '/budget', {'budget' : [
                              {

                              }]})
                            .expectStatus(422)
                            .expectJSON({errors: ['Can not update budget for task that is Accepted and paid']})
                            .toss();
            	})
            	.toss();
        })
        .toss();
    })
	.toss();

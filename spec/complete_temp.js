var config = require('./config');
var url = config.url;

frisby.create('Correct invoice')
    .post(url + '/invoices',
    {
        "external_id": '67899000000303011'
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

            	// Create task1
            	// Budget task1 with order

            	// Create task2
            	// Budget task1 with suborder
            	// Set task2 accepted

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

                    // Can not complete order - task1 is not accepted

                    // Assign resolver to task1

                    // Set task1 accepted

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

					//TODO Check team income balance ++

                    frisby.create('Correctly uncomplete order')
		               	.delete(url + '/order/' + order.id + '/complete/')
		               	.expectStatus(200)
		               	.toss();
		            

		            //TODO Check team income balance --

                    //Complete order
                    //Set task1 un-accepted
                    // Check that order is uncompleted
                    // Check that suborder is uncompleted
                    // Check team income balance

                    //Complete order
                    //Set task2 un-accepted
                    // Check that order is uncompleted
                    // Check that suborder is uncompleted
                    // Check team income balance


                    //Set task1 accepted
                    //Complete order
                    //Set invoice un-paid
                    // Check that order is uncompleted
                    // Check team income balance                    

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

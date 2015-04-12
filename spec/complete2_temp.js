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

		      frisby.create('Set invoice paid')
		        .post(url + '/invoice/' + invoice.id + '/paid')
		        .expectStatus(200)
		        .toss();
    
 
              frisby.create('Create suborder from paid order')
                .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 20, 'team' : {'id' : 2}, 'name' : 'super order'})
                .expectStatus(201)
                .afterJSON(function(subOrder) {

                    //Create task
                    //Set budget from parent order

                    frisby.create('Can complete parent order')
                    	.post(url + '/order/' + order.id + '/complete/')
                    	.expectStatus(200)
                    	.toss();

                    frisby.create('Can not delete suborder when parent order completed')
                        .delete(url + '/order/' + subOrder.id)
                        .expectStatus(422)
                        .expectJSON({errors:['Can not delete suborder when parent order completed']})
                        .toss();

                    //Increase task1 budget
                    //Can not change budget for completed order
                    //Remove budget from task1
                    //Can not change budget for completed order

                    //Create task2
                    //Set budget from parent subOrder
                    //Can not change budget for completed order

                })
                .toss();
            })
            .toss();
    })
    .toss();
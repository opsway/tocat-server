var frisby = require('frisby');
var config = require('./config');
var url = config.url;

frisby.create('Correct order creation')
  .post(url + '/orders',
       {
          "invoiced_budget": 1500.00,
          "allocatable_budget": 1000.00,
          "name" : "Test",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
       })
  .expectStatus(201)
  .toss();

frisby.create('Main invoice')
	.post(url + '/invoices',
        {
          "external_id": '99999999'
        })
    .expectStatus(201)
    .afterJSON(function(invoice){

    	frisby.create('Set invoice paid')
                            .post(url + '/invoice/' + invoice.id + '/paid')
                            .expectStatus(200)
                            .toss();

		frisby.create('Second order creation')
		      .post(url + '/orders',
		       {
		          "invoiced_budget": 2000.00,
		          "allocatable_budget": 500.00,
		          "name" : "Test2",
		          "description" : "This is just a test order for SuperClient",
		          "team":  {
		            "id" : 1
		          }
		       })
		      .afterJSON(function(order){

			    	frisby.create('Invoice order with correct invoice')
			                .post(url + '/order/' + order.id + '/invoice', {'invoice_id' : invoice.id})
			                .expectStatus(200)
			                .toss();

					frisby.create('Another task creation')
                            .post(url + '/tasks', {"external_id": "TST-102" })
                            .expectStatus(201)
                            .toss();

		            frisby.create('Correct task creation')
		              	.post(url + '/tasks', {"external_id": "TST-102" })
		              	.expectStatus(201)
		              	.afterJSON(function(task){
		                 	    frisby.create('Set task budgets')
    		                   		.post(url + '/task/' + task.id + '/budget', {'budget' : [
    		                       		{
    		                         		'order_id' : order.id,
    		                         		'budget'   : 100
    		                       		}
    		                     	]})
    		                   		.expectStatus(200)
    		                   		.toss();

		                   		frisby.create("Check that task is Paid, invoice was set to paid before task was created")
		                   			.get(url + "/task/" + task.id)
		                   			.expectJSON({'paid' : true})
		                   			.expectStatus(200)
		                   			.toss();

		                   		frisby.create('Set task1 accepted')
                                 	.post(url + '/task/' + task.id + '/accept')
                                     .expectStatus(200)
                                     .toss();

                                 frisby.create("Filtering on tasks - paid")
                                 	.get(url + '/tasks' + '?paid=true')
                                 	.expectStatus(200)
                                 	.afterJSON(function(tasks){
                                 			expect(tasks.length).toBeEqualOrGreater(1);
                                 			tasks.foreach(function(task){
                                 				frisby.create('Check that found task is paid')
                                 					.get(url + '/task' + task.id)
                                 					.expectStatus(200)
                                 					.expectJSON({'paid' : true})
                                                     .toss();
                                             })


											            frisby.create("Get only paid tasks with boolean as 1")
			                                 	.get(url + '/tasks/' + '?paid=1')
			                                 	.expectStatus(200)
			                                 	.afterJSON(function(tasks2){
			                                 			expect(tasks.length).toBeEqual(tasks2.length);
			                                 		})
			                                 	.toss();

                                 		})
                                 	.toss();

                                 frisby.create("Filtering on tasks - not paid")
                                 	.get(url + '/tasks/' + '?paid=false')
                                 	.expectStatus(200)
                                 	.afterJSON(function(tasks){
                                 			expect(tasks.length).toBeEqualOrGreater(1);
                                 			tasks.forEach(function(task) {
                                 				frisby.create('Check that found task is paid')
                                 					.get(url + '/task' + task.id)
                                 					.expectStatus(200)
                                 					.expectJSON({'paid' : true})
                                          .toss();
                                 			})
                                  })
                                  .toss();

                                 frisby.create("Get only paid tasks with boolean as 0")
                                                 .get(url + '/tasks' + '?paid=0')
                                                 .expectStatus(200)
                                                 .afterJSON(function(tasks2){
                                                         expect(tasks.length).toBeEqual(tasks2.length);
                                                     })
                                                 .toss();

                                 frisby.create("Sorting on tasks")
                                 	.get(url + '/tasks' + '?sorted_by=budget_desc')
                                 	.expectStatus(200)
                                 	.afterJSON(function(tasks){
                                 		previousTaskBudget = 0;
                                 		tasks.forEach(function(task){
                                   			if (previousTaskBudget == 0) {
                                   				previousTaskBudget == task.budget;
                                   			} else {
                                   				expect(task.budget).toBeEqualOrGreater(previousTaskBudget);
                                   			}
                                   		}
                                   	)
                                  })
                                 	.toss();

                                 frisby.create("Limit results on tasks")
                                 	.get(url + '/tasks' + '?limit=10')
                                 	.expectStatus(200)
                                 	.afterJSON(function(tasks){
                                 		expect(tasks.length).toBe(10);
                                 	})
                                 	.toss();

                                 frisby.create("Unexistent page for results on tasks")
                                 	.get(url + '/tasks' + '?limit=10&page=100000000')
                                 	.expectStatus(200)
                                 	.afterJSON(function(tasks){
                                 		expect(tasks.length).toBe(0);
                                 	})
                                 	.toss();

		      		 	})
		      			.expectStatus(201)
		      			.toss();
		      })
		      .toss();
    })
    .toss();

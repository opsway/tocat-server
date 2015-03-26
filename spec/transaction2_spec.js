//Check the following sequence:
// Resolver=id, Accepted=false, Paid=true, set accepted=true

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
                .post(url + '/tasks', {"external_id": "REDMINE-1021" })
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

 						frisby.create('Set task Resolver id=2')
                            .post(url + '/task/' + task.id + '/resolver', {'user_id' : 2})
                            .expectStatus(200)
                            .toss();		

						frisby.create('Set invoice as paid')
               				.post(url + '/invoice/' + invoice.id + '/paid')
               				.expectStatus(200)
               				.toss();

						frisby.create('Get balance account of resolver id=2')
                            .get(url + '/user/2')
                            .expectStatus(200)
                            .afterJSON(function(user){
                                balance_user_2 = user.balance_account_state;

                                frisby.create('Get balance account of team2')
                                    .get(url + '/team/2')
                                    .expectStatus(200)
                                    .afterJSON(function(team){
                                        balance_team_2 = team.balance_account_state;
			                                frisby.create('Get current Transactions')
			                                    .get(url + '/transactions/?limit=9999999')
			                                    .expectStatus(200)
			                                    .afterJSON(function(transactionsBefore){
													
													frisby.create('Set task accepted')
                            							.post(url + '/task/' + task.id + '/accept')
                            							.expectStatus(200)
                            							.toss();
													
													frisby.create('Get new balance account of resolver id=2')
													    .get(url + '/user/2')
													    .expectStatus(200)
													    .afterJSON(function(user){
													        frisby.create('Get balance account of team2')
													            .get(url + '/team/2')
													            .expectStatus(200)
													            .afterJSON(function(team){

													            	//Expecting 3 transactions:
																	//User balance
																	//Team balance
																	//Team payment
																    frisby.create('Check new transactions')
																        .get(url + '/transactions/?limit=9999999')
																        .expectStatus(200)
																        .afterJSON(function(transactionsAfter){
																        	expect(user.balance_account_state).toBe(balance_user_2 + 32);
																			expect(team.balance_account_state).toBe(balance_team_2 + 32);
																			

																			expect(transactionsAfter.length - transactionsBefore.length).toBe(3);
																			
																			userBalanceTransactionsNumber = 0;
																			teamBalanceTransactionsNumber = 0;
																			teamPaymentTransactionsNumber = 0;

																			transactionsBefore.forEach(function(tx){
																				if (tx.comment == "Accepted and paid issue REDMINE-1021") {
																					if (tx['type'] == "balance" && tx.owner['type'] = 'user') {
																						userBalanceTransactionsNumber +=1;
																					}
																					if (tx['type'] == "balance" && tx.owner['type'] = 'team') {
																						teamBalanceTransactionsNumber +=1;
																					}
																					if (tx['type'] == "payment" && tx.owner['type'] = 'team') {
																						teamPaymentTransactionsNumber +=1;
																					}
										                                   		}
										                                   	});

																			transactionsAfter.forEach(function(tx){
																				if (tx.comment == "Accepted and paid issue REDMINE-1021") {
																					if (tx['type'] == "balance" && tx.owner['type'] = 'user') {
																						userBalanceTransactionsNumber -=1;
																					}
																					if (tx['type'] == "balance" && tx.owner['type'] = 'team') {
																						teamBalanceTransactionsNumber -=1;
																					}
																					if (tx['type'] == "payment" && tx.owner['type'] = 'team') {
																						teamPaymentTransactionsNumber -=1;
																					}
										                                   		}
										                                   	});

										                                   	expect(userBalanceTransactionsNumber).toBe(1);
										                                   	expect(teamPaymentTransactionsNumber).toBe(1);
										                                   	expect(teamBalanceTransactionsNumber).toBe(1);

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
            	})
            	.toss();
         })
        .toss();
    })
	.toss();
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
                        .post(url + '/tasks', {"external_id": "REDMINE-1021" })
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
                                .post(url + '/tasks', {"external_id": "REDMINE-1023" })
                                .expectStatus(201)
                                .afterJSON(function(task2){

                                    frisby.create('Set task budgets')
                                        .post(url + '/task/' + task1.id + '/budget', {'budget' : [
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
                                        .post(url + '/task/' + task1.id + '/accept')
                                        .expectStatus(200)
                                        .toss();

                                    frisby.create('Can complete parent order')
                                        .post(url + '/order/' + order.id + '/complete/')
                                        .expectStatus(200)
                                        .toss();

                                    frisby.create('Get balance account of team1')
                                        .get(url + '/team/1')
                                        .expectStatus(200)
                                        .afterJSON(function(team1){
                                            income_team_1 = team1.income_account_state;
                                                
                                            frisby.create('Get balance account of team2')
                                                .get(url + '/team/2')
                                                .expectStatus(200)
                                                .afterJSON(function(team2){
                                                    income_team_2 = team2.income_account_state;

                                                    frisby.create('Get current Transactions')
                                                        .get(url + '/transactions?limit=9999999')
                                                        .expectStatus(200)
                                                        .afterJSON(function(transactionsBefore){

                                                            
                                                            frisby.create('Correctly uncomplete order')
                                                                .delete(url + '/order/' + order.id + '/complete/')
                                                                .expectStatus(200)
                                                                .toss();

                                                            frisby.create('Get current Transactions')
                                                                .get(url + '/transactions?limit=9999999')
                                                                .expectStatus(200)
                                                                .afterJSON(function(transactionsAfter){

                                                                    frisby.create('Get balance account of team1')
                                                                        .get(url + '/team/1')
                                                                        .expectStatus(200)
                                                                        .afterJSON(function(team1){
                                                                            income_team_1 = team1.income_account_state;
                                                                                
                                                                            frisby.create('Get balance account of team2')
                                                                                .get(url + '/team/2')
                                                                                .expectStatus(200)
                                                                                .afterJSON(function(team2){
                                                                                    income_team_2 = team2.income_account_state;

                                                                                    expect(team1.income_account_state).toBe(income_team_1 - 100);
                                                                                    expect(team2.income_account_state).toBe(income_team_2 - 10);
                                                                                    expect(transactionsAfter.length - transactionsBefore.length).toBe(2);

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
    })
    .toss();
})
.toss();


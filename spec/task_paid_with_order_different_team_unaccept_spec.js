var config = require('./config');
var url = config.url;

frisby.create('Correct invoice')
    .post(url + '/invoices',
    {
        "external_id": '67899000000303011' + Math.floor(Math.random() * 1000000)
    })
    .expectStatus(201)
    .afterJSON(function(invoice){

              frisby.create('Invoice order id=1 with correct invoice. Order is hardcoded in import.sql')
                .post(url + '/order/1/invoice', {'invoice_id' : invoice.id})
                .expectStatus(200)
                .toss();

            frisby.create('Set task id=1 (hardcoded) accepted')
                .post(url + '/task/1/accept')
                .expectStatus(200)
                .toss();

            ////////
            frisby.create('Set invoice paid')
                .post(url + '/invoice/' + invoice.id + '/paid')
                .expectStatus(200)
                .toss();
              
            frisby.create('Get balance account of resolver id=1')
                            .get(url + '/user/1')
                            .expectStatus(200)
                            .afterJSON(function(user){
                                balance_user = user.balance_account_state;

                                frisby.create('Get balance account of team2')
                                    .get(url + '/team/2')
                                    .expectStatus(200)
                                    .afterJSON(function(team){
                                        balance_team = team.balance_account_state;
                                            frisby.create('Get current Transactions')
                                                .get(url + '/transactions?limit=9999999')
                                                .expectStatus(200)
                                                .afterJSON(function(transactionsBefore){


                                                    frisby.create('Remove task accepted flag')
                                                        .delte(url + '/task/1/accept')
                                                        .expectStatus(200)
                                                        .toss();
                                                    
                                                    frisby.create('Get new balance account of resolver id=1')
                                                        .get(url + '/user/1')
                                                        .expectStatus(200)
                                                        .afterJSON(function(user){
                                                            frisby.create('Get balance account of team2')
                                                                .get(url + '/team/2')
                                                                .expectStatus(200)
                                                                .afterJSON(function(team){

                                                                    //Expecting 3 transactions:
                                                                    //User1 balance 
                                                                    //Team2 balance
                                                                    //Team2 payment
                                                                    frisby.create('Check new transactions')
                                                                        .get(url + '/transactions?limit=9999999')
                                                                        .expectStatus(200)
                                                                        .afterJSON(function(transactionsAfter){
                                                                            expect(user.balance_account_state).toBe(balance_user - 30);
                                                                            expect(team.balance_account_state).toBe(balance_team - 30);


                                                                            expect(transactionsAfter.length - transactionsBefore.length).toBe(3);

                                                                            userBalanceTransactionsNumber = 0;
                                                                            teamBalanceTransactionsNumber = 0;
                                                                            teamPaymentTransactionsNumber = 0;

                                                                            transactionsBefore.forEach(function(tx){
                                                                                if (tx.comment == "Reopening issue " + task_id) {

                                                                                    if (tx['type'] == "balance" && tx.owner["type"] == 'user') {
                                                                                        userBalanceTransactionsNumber +=1;
                                                                                    }
                                                                                    if (tx["type"] == "balance" && tx.owner["type"] == 'team') {
                                                                                        teamBalanceTransactionsNumber +=1;
                                                                                    }
                                                                                    if (tx["type"] == "payment" && tx.owner["type"] == 'team') {
                                                                                        teamPaymentTransactionsNumber +=1;
                                                                                    }
                                                                                }
                                                                            });

                                                                            transactionsAfter.forEach(function(tx){
                                                                                if (tx.comment == "Reopening issue " + task_id) {
                                                                                    if (tx['type'] == "balance" && tx.owner["type"] == 'user') {
                                                                                        userBalanceTransactionsNumber -=1;
                                                                                    }
                                                                                    if (tx["type"] == "balance" && tx.owner["type"] == 'team') {
                                                                                        teamBalanceTransactionsNumber -=1;
                                                                                    }
                                                                                    if (tx["type"] == "payment" && tx.owner["type"] == 'team') {
                                                                                        teamPaymentTransactionsNumber -=1;
                                                                                    }
                                                                                }
                                                                            });

                                                                            expect(userBalanceTransactionsNumber).toBe(-1);
                                                                            expect(teamPaymentTransactionsNumber).toBe(-1);
                                                                            expect(teamBalanceTransactionsNumber).toBe(-1);
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

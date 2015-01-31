//Can not link to order already paid invoice ?????
//when you can not remove invoice from order?
//when you can not make-unpaid
//internal orders


var frisby = require('frisby');
var url = 'http://tocat.opsway.com';


frisby.create('Correct invoice')
    .post(url + '/invoice',

        {
          "external_id": '67899000000303002'
        })
    .expectStatus(201)
    .afterJSON(function(invoice){
      frisby.create('Delete invoice')
            .delete(url + '/invoice/' + invoice.id)
            .expectStatus(200)
            .toss();
    })
    .toss();


frisby.create('Correct invoice')
    .post(url + '/invoice',
        {
          "external_id": '67899000000303001'
        })
    .expectStatus(201)
    .afterJSON(function(invoice){
      frisby.create('Correct order creation')
        .post(url + '/order',
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
          frisby.create('Invoice order with inexistent invoice')
            .post(url + '/order/' + order.id + '/invoice', {'invoice_id' : 99999999})
            .expectStatus(422)
            .expectJSON({error:'ORDER_ERROR'})
            .expectBodyContains('Invoice does not exist')
            .toss();

          frisby.create('Invoice order with correct invoice')
            .post(url + '/order/' + order.id + '/invoice', {'invoice_id' : invoice.id})
            .expectStatus(200)
            .toss();

          frisby.create('Delete used invoice is not allowed')
            .delete(url + '/invoice/' + invoice.id)
            .expectStatus(422)
            .expectJSON({error:'ORDER_ERROR'})
            .expectBodyContains('Invoice is linked to orders')
            .toss();

          frisby.create('Create correct suborder')
            .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 50, 'team' : {'id' : 2}, 'name' : 'super order'})
            .expectStatus(201)
            .afterJSON(function(subOrder1) {
              frisby.create('Create second correct suborder for the same team as parent order')
                .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 30, 'team' : {'id' : 1}, 'name' : 'super order'})
                .expectStatus(201)
                .afterJSON(function(subOrder2) {
                   frisby.create('Correct task creation')
                    .post(url + '/task', {"external_id": "TST-102" })
                    .expectStatus(201)
                      .afterJSON(function(task){
                        frisby.create('Set task budgets')
                          .post(url + '/task/' + task.id + '/budget', {'budget' : [
                              {
                                'order_id' : order.id,
                                'budget'   : 30
                              },
                              {
                                'order_id' : subOrder2.id,
                                'budget'   : 20
                              }
                            ]})
                          .expectStatus(200)
                          .afterJSON(function(){
                            frisby.create('Set task Resolver')
                              .post(url + '/task/' + task.id + '/resolver', {'user_id' : 1})
                              .expectStatus(200)
                              .afterJSON(function(){
                                frisby.create('Another task creation')
                                  .post(url + '/task', {"external_id": "TST-102" })
                                  .expectStatus(201)
                                    .afterJSON(function(task2){
                                      frisby.create('Set task budgets')
                                        .post(url + '/task/' + task2.id + '/budget', {'budget' : [
                                            {
                                              'order_id' : subOrder1.id,
                                              'budget'   : 20
                                            }
                                          ]})
                                        .expectStatus(200)
                                        .afterJSON(function(){
                                          frisby.create('Set task Resolver')
                                            .post(url + '/task/' + task2.id + '/resolver', {'user_id' : 2})
                                            .inspectBody()
                                            .expectStatus(200)
                                            .afterJSON(function(){

                                              frisby.create('Set invoice paid')
                                                .post(url + '/invoice/' + invoice.id + '/paid')
                                                .expectStatus(200)
                                                .afterJSON(function(){
                                                  frisby.create('Get balance account of resolver id=1')
                                                    .get(url + '/user/1')
                                                    .expectStatus(200)
                                                    .afterJSON(function(user){
                                                      balance_user_1 = user.balance_account_state;

                                                      frisby.create('Get balance account of team1')
                                                        .get(url + '/team/1')
                                                        .expectStatus(200)
                                                        .afterJSON(function(team){
                                                            balance_team_1 = team.balance_account_state;

                                                            frisby.create('Set task1 accepted')
                                                              .post(url + '/task/' + task.id + '/accept')
                                                              .expectStatus(200)
                                                              .afterJSON(function(){
                                                                frisby.create('Check that task1 is accepted&paid')
                                                                  .get(url + '/task/' + task.id)
                                                                  .expectStatus(200)
                                                                  .expectJSON({'paid' : true, 'accepted' : true})
                                                                  .toss();
                                                                frisby.create('Check that task2 is not paid')
                                                                  .get(url + '/task/' + task2.id)
                                                                  .expectStatus(200)
                                                                  .expectJSON({'paid' : false})
                                                                  .toss();
                                                                //TODO phase2 Check that you can not complete parent order')

                                                                frisby.create('Check that user balance is updated')
                                                                  .get(url + '/user/1')
                                                                  .expectStatus(200)
                                                                  .afterJSON(function(user){
                                                                      expect(user.balance_account_state).equals(balance_user_1 + 50);
                                                                  })
                                                                  .toss();
                                                                frisby.create('Check that team1 balance is updated')
                                                                  .get(url + '/team/1')
                                                                  .expectStatus(200)
                                                                  .afterJSON(function(team){
                                                                      expect(team.balance_account_state).equals(balance_team_1 + 50);
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
                                                                                  frisby.create('Set task2 accepted')
                                                                                    .post(url + '/task/' + task2.id + '/accept')
                                                                                    .expectStatus(200)
                                                                                    .afterJSON(function(){
                                                                                      frisby.create('Check that task2 is accepted&paid')
                                                                                        .get(url + '/task/' + task2.id)
                                                                                        .expectStatus(200)
                                                                                        .expectJSON({'paid' : true, 'accepted' : true})
                                                                                        .toss();

                                                                                      //TODO phase2 Check that you CAN complete parent order')

                                                                                      frisby.create('Check that user2 balance is updated')
                                                                                        .get(url + '/user/2')
                                                                                        .expectStatus(200)
                                                                                        .afterJSON(function(user){
                                                                                            expect(user.balance_account_state).equals(balance_user_2 + 20);
                                                                                        })
                                                                                        .toss();
                                                                                      frisby.create('Check that team2 balance is updated')
                                                                                        .get(url + '/team/2')
                                                                                        .expectStatus(200)
                                                                                        .afterJSON(function(team){
                                                                                            expect(team.balance_account_state).equals(balance_team_2 + 20);
                                                                                        })
                                                                                        .toss();
                                                                                      frisby.create('Unset resolver from task2')
                                                                                        .delete(url + '/task/' + task2.id + '/resolver')
                                                                                        .expectStatus(200)
                                                                                        .afterJSON(function(){
                                                                                          frisby.create('Check no resolver for task2')
                                                                                            .get(url + '/task/' + task2.id)
                                                                                            .expectStatus(200)
                                                                                            .expectJSON({'resolver' : {}})
                                                                                            .afterJSON(function(){
                                                                                                frisby.create('Check that user2 balance is decreased')
                                                                                                  .get(url + '/user/2')
                                                                                                  .expectStatus(200)
                                                                                                  .afterJSON(function(user){
                                                                                                      expect(user.balance_account_state).equals(balance_user_2);
                                                                                                  })
                                                                                                  .toss();
                                                                                                frisby.create('Check that team2 balance is decreased')
                                                                                                  .get(url + '/team/2')
                                                                                                  .expectStatus(200)
                                                                                                  .afterJSON(function(team){
                                                                                                      expect(team.balance_account_state).equals(balance_team_2);
                                                                                                      frisby.create('Set invoice unpaid')
                                                                                                        .delete(url + '/invoice/' + invoice.id + '/paid')
                                                                                                        .expectStatus(200)
                                                                                                        .expectJSON(function(){
                                                                                                           frisby.create('Parent order is unpaid')
                                                                                                            .get(url + '/order/' + order.id)
                                                                                                            .expectStatus(200)
                                                                                                            .expectJSON({'paid' : false})
                                                                                                            .toss();
                                                                                                           frisby.create('Suborder1 is unpaid')
                                                                                                            .get(url + '/order/' + subOrder1.id)
                                                                                                            .expectStatus(200)
                                                                                                            .expectJSON({'paid' : false})
                                                                                                            .toss();
                                                                                                           frisby.create('suborder2 is unpaid')
                                                                                                            .get(url + '/order/' + subOrder2.id)
                                                                                                            .expectStatus(200)
                                                                                                            .expectJSON({'paid' : false})
                                                                                                            .toss();
                                                                                                           frisby.create('Task1 is unpaid')
                                                                                                            .get(url + '/task/' + task.id)
                                                                                                            .expectStatus(200)
                                                                                                            .expectJSON({'paid' : false})
                                                                                                            .toss();
                                                                                                           frisby.create('Task2 is unpaid')
                                                                                                            .get(url + '/task/' + task2.id)
                                                                                                            .expectStatus(200)
                                                                                                            .expectJSON({'paid' : false})
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
    })
    .toss();

var frisby = require('frisby');
var config = require('./config');
var url = config.url;


frisby.create('Correct task creation')
 .post(url + '/task', {"external_id": "TST-101" })
 .expectStatus(201)
 .afterJSON(function(task){
    frisby.create('Initial task settings')
      .get(url + '/task/' + task.id)
      .expectStatus(200)
      .expectJSON({'budget' : 0, 'paid' : false, 'resolver' : {}, 'accepted' : false, 'external_id' : 'TST-101'})
      .afterJSON(function(){
          frisby.create('DELETE task - not allowed')
            .delete(url + '/task/' + task.id)
            .expectStatus(405)
            .toss();

          frisby.create('Fields should not be updatable directly')
            .post(url + '/task/' + task.id,
            {
              'paid' : true,
              'budget' : 10,
              'resolver' : {
                'id' : 1
              },
              'accepted' : true
            })
            .expectStatus(405)
            .afterJSON(function(){
              frisby.create('Check that settings are not changed')
                .get(url + '/task/' + task.id)
                .expectStatus(200)
                .expectJSON({'budget' : 0, 'paid' : false, 'resolver' : {}, 'accepted' : false, 'external_id' : 'TST-101'})
                .toss();
            })
            .toss();
      })
      .toss();
 })
 .toss();

frisby.create('Missed task external id')
  .post(url + '/task',{})
 .expectStatus(422)
 .expectJSON({error:'TASK_ERROR'})
 .expectBodyContains('Missing external task ID')
 .toss();


frisby.create('Correct order creation')
  .post(url + '/order',
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
  .afterJSON(function(order) {
    frisby.create('Second order creation')
      .post(url + '/order',
       {
          "invoiced_budget": 2000.00,
          "allocatable_budget": 500.00,
          "name" : "Test2",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
       })
      .afterJSON(function(order2){
            frisby.create('Correct task creation')
              .post(url + '/task', {"external_id": "TST-102" })
              .expectStatus(201)
              .afterJSON(function(task){
                frisby.create('Set task budgets')
                  .post(url + '/task/' + task.id + '/budget', {'budget' : [
                      {
                        'order_id' : order.id,
                        'budget'   : 100
                      },
                      {
                        'order_id' : order2.id,
                        'budget'   : 150
                      }
                    ]})
                  .expectStatus(200)
                  .afterJSON(function(){
                      frisby.create('Test accepted status setup')
                        .post(url + '/task/' + task.id + '/accept')
                        .expectStatus(200)
                        .afterJSON(function(){
                          frisby.create('Check accepted status in task')
                            .get(url + '/task/' + task.id)
                            .expectJSON({'accepted' : true})
                            .expectStatus(200)
                            .toss();

                          frisby.create('Remove accepted status')
                            .delete(url + '/task/' + task.id + '/accept')
                            .expectStatus(200)
                            .afterJSON(function(){
                              frisby.create('Check accepted status in task')
                                .get(url + '/task/' + task.id)
                                .expectJSON({'accepted' : false})
                                .expectStatus(200)
                                .toss();
                            })
                            .toss();
                        })
                        .toss();

                      frisby.create('Check updated budget')
                        .get(url + '/task/' + task.id)
                        .expectStatus(200)
                        .expectJSON({'budget' : 250})
                        .toss();

                      frisby.create('Can not delete order, when budget is used for tasks')
                        .delete(url + '/order/' + order.id)
                        .expectStatus(422)
                        .expectJSON({error:'ORDER_ERROR'})
                        .expectBodyContains('You can not delete order that is used in task budgeting')
                        .toss();

                      frisby.create('Can not delete order, when budget is used for tasks')
                        .delete(url + '/order/' + order2.id)
                        .expectStatus(422)
                        .expectJSON({error:'ORDER_ERROR'})
                        .expectBodyContains('You can not delete order that is used in task budgeting')
                        .toss();

                      frisby.create('Check budgets')
                        .get(url + '/task/' + task.id + '/budget')
                        .expectStatus(200)
                        .expectJSON({
                          'budget' : [
                            {
                              'order_id' : order.id,
                              'budget'   : 100
                            },
                            {
                              'order_id' : order2.id,
                              'budget'   : 150
                            }
                          ]})
                        .toss();

                      frisby.create('Can not change order team when used for task budgets')
                        .patch(url + '/order/' + order.id, {'team': {'id': 2}})
                        .expectStatus(422)
                         .expectJSON({error:'ORDER_ERROR'})
                         .expectBodyContains('Can not change order team - order is used in tasks')
                         .toss();
                  })
                  .toss();
      })
      .expectStatus(201)
      .toss();

      })
      .toss();
  })
  .toss();


  frisby.create('Missed task external id')
  .post(url + '/task',{})
 .expectStatus(422)
 .expectJSON({error:'TASK_ERROR'})
 .expectBodyContains('Missing external task ID')
 .toss();


frisby.create('Correct order creation for unusual team')
  .post(url + '/order',
       {
          "invoiced_budget": 1500.00,
          "allocatable_budget": 1000.00,
          "name" : "Test",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 2
          }
       })
  .expectStatus(201)
  .afterJSON(function(order) {
    frisby.create('Second order creation')
      .post(url + '/order',
       {
          "invoiced_budget": 2000.00,
          "allocatable_budget": 500.00,
          "name" : "Test2",
          "description" : "This is just a test order for SuperClient",
          "team":  {
            "id" : 1
          }
       })
      .afterJSON(function(order2){
      frisby.create('Correct task creation')
        .post(url + '/task', {"external_id": "TST-103" })
        .expectStatus(201)
        .afterJSON(function(task){
          frisby.create('Set task Resolver from different team than we will try to budget')
            .post(url + '/task/' + task.id + '/resolver', {'user_id' : 2})
            .expectStatus(200)
            .afterJSON(function(){
              frisby.create('Check task Resolver')
                .get(url + '/task/' + task.id)
                .expectStatus(200)
                .expectJSON({'resolver' : {'id' : 2}})
                .afterJSON(function(){
                  frisby.create('Set task budgets for incorrect team orders')
                    .post(url + '/task/' + task.id + '/budget', {'budget' : [
                      {
                        'order_id' : order.id,
                        'budget'   : 100
                      },
                      {
                              'order_id' : order2.id,
                              'budget'   : 150
                      }
                    ]})
                    .expectStatus(422)
                    .expectJSON({error:'TASK_ERROR'})
                    .expectBodyContains('Task resolver is from different team than order')
                    .afterJSON(function(){
                      frisby.create('Remove resolver from task')
                        .delete(url + '/task/' + task.id + '/resolver')
                        .expectStatus(200)
                        .afterJSON(function(){
                          frisby.create('Check that there is no resolver in task')
                            .get(url + '/task/' + task.id)
                            .expectStatus(200)
                            .expectJSON({'resolver' : {}})
                            .afterJSON(function(){
                              frisby.create('Set task budgets without resolver')
                                .post(url + '/task/' + task.id + '/budget', {'budget' : [
                                  {
                                    'order_id' : order.id,
                                    'budget'   : 100
                                  },
                                  {
                                    'order_id' : order2.id,
                                    'budget'   : 150
                                  }
                                ]})
                                .expectStatus(422)
                                .expectJSON({error: 'TASK_ERROR'})
                                .expectBodyContains('Orders are created for different teams')
                                .afterJSON(function(){
                                  frisby.create('Set correct task budget')
                                    .post(url + '/task/' + task.id + '/budget', {'budget' : [
                                      {
                                        'order_id' : order2.id,
                                        'budget'   : 300
                                      }]})
                                      .expectStatus(200)
                                      .afterJSON(function(){

                                        frisby.create('Try to change resolver to different team')
                                          .post(url + '/task/' + task.id + '/resolver', {'user_id' : 3})
                                          .expectStatus(422)
                                          .expectJSON({error: 'TASK_ERROR'})
                                          .expectBodyContains('Task resolver is from different team than order')
                                          .toss();

                                        frisby.create('Increase budget from the same order')
                                          .post(url + '/task/' + task.id + '/budget',  {'budget' : [
                                            {
                                              'order_id' : order2.id,
                                              'budget'   : 450
                                            }]})
                                          .expectStatus(200)
                                          .afterJSON(function(){
                                            frisby.create('Can not assign more budget that is available on order')
                                              .post(url + '/task/' + task.id + '/budget',  {'budget' : [
                                                {
                                                  'order_id' : order2.id,
                                                  'budget'   : 501
                                                }]})
                                              .expectStatus(422)
                                              .expectJSON({error: 'TASK_ERROR'})
                                              .expectBodyContains('You can not assign more budget than is available on order')
                                              .afterJSON(function(){
                                                frisby.create('Set task Resolver from different team than we set budget')
                                                  .post(url + '/task/' + task.id + '/resolver', {'user_id' : 2})
                                                  .expectStatus(422)
                                                  .expectJSON({error:'TASK_ERROR'})
                                                  .expectBodyContains('Task resolver is from different team than order')
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

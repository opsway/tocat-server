//Test task financing from wrong team order

var frisby = require('frisby');
var url = 'http://tocat.opsway.com';

frisby.create('Correct task creation')
 .post(url + '/task', {"external_id": "TST-101" })
 .expectStatus(201)
 .afterJSON(function(task){
    frisby.create('Initial task settings')
      .get(url + '/task/' + task.id)
      .expectStatus(200)
      .expectJSON({'budget' : 0, 'paid' : false, 'resolver' : {}, 'accepted' : false, 'external_id' : 'TST-101'})
      .afterJSON(function(){
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
                      frisby.create('Check updated budget')
                        .get(url + '/task/' + task.id)
                        .expectStatus(200)
                        .expectJSON({'budget' : 250})
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
                          ]}
                        )
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

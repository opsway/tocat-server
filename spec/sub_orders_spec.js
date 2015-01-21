// Fail delete when financing issues
// Fail delete when parent order completed

var frisby = require('frisby');
var url = 'http://localhost:3000';

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
        }

        )
    .expectStatus(201)
    .afterJSON(function(order) {
      frisby.create('No team specified in suborder creation')
        .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 50, 'name' : "new order"})
        .expectStatus(422)
        .expectJSON({error:'ORDER_ERROR'})
        .expectBodyContains('Team value is missing')
        .toss();

      frisby.create('No allocatable_budget specified in suborder creation')
        .post(url + '/order/' + order.id + '/suborder', {'team': {'id' : 2}, 'name' : "new order"})
        .expectStatus(422)
        .expectJSON({error:'ORDER_ERROR'})
        .expectBodyContains('Allocatable budget is missing')
        .toss();

      frisby.create('No order name specified in suborder creation')
        .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 50, 'team': {'id' : 2}})
        .expectStatus(422)
        .expectJSON({error:'ORDER_ERROR'})
        .expectBodyContains('Order name can not be empty')
        .toss();


      frisby.create('Create correct suborder')
        .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 50, 'team' : {'id' : 2}, 'name' : 'super order'})
        .expectStatus(201)
        .afterJSON(function(subOrder) {
          frisby.create('Invoiced budget should be equal to allocatable') // why free_budget = 50? it suppouse to be 0
            .get(url + '/order/' + subOrder.id)
            .expectStatus(200)
            .expectJSON({'invoiced_budget' : 50, 'free_budget' : 50, 'parent_order' : {'id' : order.id, "href" : "/order/" + subOrder.id}})
            .toss();

          frisby.create('Allocatable budget on parent order should decrease')
            .get(url + '/order/' + order.id)
            .expectStatus(200)
            .expectJSON({'allocatable_budget' : 50, 'free_budget' : 50})
            .toss()

          frisby.create('Suborder can not be created from suborder')
            .post(url + '/order/' + subOrder.id + '/suborder', {'allocatable_budget': 50, 'team' : {'id' : 3},  'name' : 'super order'})
            .expectStatus(422)
            .expectJSON({error:'ORDER_ERROR'})
            .expectBodyContains('Suborder can not be created from another suborder')
            .toss();

          frisby.create('Suborder can not be invoiced more than parent free budget')
            .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 500, 'team' : {'id' : 2}, 'name' : 'super order'})
            .expectStatus(422)
            .expectJSON({error:'ORDER_ERROR'})
            .expectBodyContains('Suborder can not be invoiced more than parent free budget')
            .toss();

          frisby.create('Suborder can not be created for the same team as parent order')
            .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 50, 'team' : {'id' : 1},  'name' : 'super order'})
            .expectStatus(422)
            .expectJSON({error:'ORDER_ERROR'})
            .expectBodyContains('Suborder can not be created for the same team as parent order')
            .toss();

          frisby.create('Create second suborder from parent order')
            .post(url + '/order/' + order.id + '/suborder', {'allocatable_budget': 20, 'team' : {'id' : 2}, 'name' : 'super order'})
            .expectStatus(201)
            .afterJSON(function(subOrder) {
              frisby.create('Allocatable budget on parent order should decrease')
                .get(url + '/order/' + order.id)
                .expectStatus(200)
                .expectJSON({'allocatable_budget' : 30, 'free_budget' : 30})
                .toss()
            });

          frisby.create('Update suborder budgets') //why 204(no content) Update action response with 201 and id of updated record, it checked in order_create_spec
            .patch(url + '/order/' + subOrder.id, {'allocatable_budget': 52, 'invoiced_budget' : 52})
            .expectStatus(204)
            .afterJSON(function(){
              frisby.create('Allocatable budget on parent order should decrease')
                .get(url + '/order/' + order.id)
                .expectStatus(200)
                .expectJSON({'allocatable_budget' : 28, 'free_budget' : 28})
                .toss()
            })
            .toss();

          frisby.create('Update suborder budget to more than available')
            .patch(url + '/order/' + subOrder.id, {'allocatable_budget': 500 , 'invoiced_budget' : 500})
            .expectStatus(422)
            .expectJSON({error:'ORDER_ERROR'})
            .expectBodyContains('Suborder can not be invoiced more than parent free budget')
            .toss();

          frisby.create('Delete suborder')
            .delete(url + '/order/' + subOrder.id)
            .expectStatus(204)
            .afterJSON(function(){
              frisby.create('Allocatable budget on parent order should increase')
                .get(url + '/order/' + order.id)
                .expectStatus(200)
                .expectJSON({'allocatable_budget' : 80, 'free_budget' : 80})
                .toss()
            })
            .toss();

        })
        .toss();
    })
    .toss();

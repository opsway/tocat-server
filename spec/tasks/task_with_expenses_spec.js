var config = require('./../config');
var url = config.url;

var task01 = Math.floor(Math.random() * (99999 - 1)) + 30;

frisby.create('Correct task creation')
    .post(url + '/tasks', {"external_id": + task01 })
    .expectStatus(201)
    .afterJSON(function(task){
        frisby.create('Set task resolver')
            .post(url + '/task/' + task.id + '/resolver', { 'user_id': 2 })
            .expectStatus(200)
            .afterJSON(function(){
                frisby.create('Setting expense to true for task with resolver set should fail')
                    .post(url + '/task/' + task.id + '/expenses')
                    .expectStatus(422)
                    .expectJSON({errors:['Please remove Resolver first to setup Expense flag.']})
                    .toss();
            }).toss();
    })
    .toss();

var task02 = Math.floor(Math.random() * (99999 - 1)) + 30;

frisby.create('Correct task creation')
    .post(url + '/tasks', {"external_id": + task02 })
    .expectStatus(201)
    .afterJSON(function(task){
        frisby.create('Set task expense')
            .post(url + '/task/' + task.id + '/expenses')
            .expectStatus(200)
            .afterJSON(function(){
                frisby.create('Setting resolver for task with expense set should fail')
                    .post(url + '/task/' + task.id + '/resolver', { 'user_id': 2 })
                    .expectStatus(422)
                    .expectJSON({errors:['You can not setup Resolver for issue that is Expense']})
                    .toss();
            }).toss();
    })
    .toss();


frisby.create('Correct order creation')
    .post(url + '/orders',
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
        frisby.create('Correct task creation')
            .post(url + '/tasks', {"external_id": Math.floor(Math.random() * (99999 - 1)) + 30})
            .expectStatus(201)
            .afterJSON(function (task) {
                frisby.create('Set task expense')
                    .post(url + '/task/' + task.id + '/expenses')
                    .expectStatus(200)
                    .afterJSON(function () {
                        frisby.create('Changing task budget should fail')
                            .post(url + '/task/' + task.id + '/budget', {
                                'budget': [
                                    {
                                        'order_id': order.id,
                                        'budget': 100
                                    }
                                ]
                            })
                            .expectStatus(422)
                            .expectJSON({errors: ['You can not update budget for Expense. Please contact administrator to remove Expense flag first']})
                            .toss();
                    }).toss();
            })
            .toss();
    })
    .toss();


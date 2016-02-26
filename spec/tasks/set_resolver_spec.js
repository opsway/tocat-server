var config = require('./../config');
var url = config.url;

var task01 = Math.floor(Math.random() * (99999 - 1)) + 30;

frisby.create('Correct task creation')
    .post(url + '/tasks', {"external_id": + task01 })
    .expectStatus(201)
    .afterJSON(function(task){
        frisby.create('Set manager as a resolver of a task should fail')
            .post(url + '/task/' + task.id + '/resolver', { 'user_id': 8 })
            .expectStatus(422)
            .expectJSON({errors:['Manager can not be set as a resolver']})
            .toss();
    })
    .toss();

var config = require('./../config');
var url = config.url;

frisby.create('Create internal order with free budget > 0')
    .post(
    url + '/orders',
    {
        "internal_order": true,
        "invoiced_budget": 1000.00,
        "allocatable_budget": 600.00,
        "name" : "Test",
        "description" : "This is just a test order for SuperClient",
        "team":  {
            "id" : 1
        }
    }
)
    .expectStatus(201)
    .afterJSON(function(order) {
        frisby.create('Complete internal order with free budget > 0 should fail')
            .post(url + '/order/' + order.id + '/complete')
            .expectStatus(422)
            .expectJSON({errors: ['Internal order can not have free budget. Please correct invoiced and allocatable budget accordingly']})
            .toss();
    }).toss();

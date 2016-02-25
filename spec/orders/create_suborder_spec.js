var config = require('./../config');
var url = config.url;

frisby.create('Create parent order')
    .post(
    url + '/orders',
    {
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
        frisby.create('Creating suborder with internal_order set to true should fail')
            .post(
            url + '/orders',
            {
                "parent_id": order.id,
                "internal_order": true,
                "invoiced_budget": 100.00,
                "allocatable_budget": 100.00,
                "name": "Test",
                "description": "This is just a test order for SuperClient",
                "team": {
                    "id": 2
                }
            }
        )
            .expectStatus(422)
            .expectJSON({errors: ["Can't set internal_order flag to suborder"]})
            .toss();
    }).toss();

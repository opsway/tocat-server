var config = require('./../config');
var url = config.url;

frisby.create('Create parent order')
    .post(
    url + '/orders',
    {
        "invoiced_budget": 1000.00,
        "allocatable_budget": 600.00,
        "name": "Test",
        "description": "This is just a test order for SuperClient",
        "team": {
            "id": 1
        }
    }
)
    .expectStatus(201)
    .afterJSON(function (parentOrder) {
        frisby.create('Create order')
            .post(
            url + '/orders',
            {
                "invoiced_budget": 100.00,
                "allocatable_budget": 100.00,
                "name": "Test",
                "description": "This is just a test order for SuperClient",
                "team": { "id": 2 }
            }
        )
            .expectStatus(201)
            .afterJSON(function (childOrder) {
                frisby.create('Set child order parent')
                    .put(
                    url + '/order/' + childOrder.id,
                    {
                        "parent_id": parentOrder.id,
                        "invoiced_budget": 100.00,
                        "allocatable_budget": 100.00,
                        "name": "Test",
                        "description": "This is just a test order for SuperClient",
                        "team": { "id": 2 }
                    }
                )
                    .expectStatus(200)
                    .afterJSON(function () {
                        frisby.create('Parent free budget should be changed')
                            .get(url + '/order/' + parentOrder.id)
                            .expectStatus(200)
                            .expectJSON({'free_budget': 500})
                            .toss();

                        frisby.create("Create new parent")
                            .post(
                            url + '/orders',
                            {
                                "invoiced_budget": 1000.00,
                                "allocatable_budget": 1000.00,
                                "name": "Test",
                                "description": "This is just a test order for SuperClient",
                                "team": { "id": 1 }
                            }
                        )
                            .expectStatus(201)
                            .afterJSON(function (newParent) {
                                frisby.create('Set child order new parent')
                                    .put(
                                    url + '/order/' + childOrder.id,
                                    {
                                        "parent_id": newParent.id,
                                        "invoiced_budget": 100.00,
                                        "allocatable_budget": 100.00,
                                        "name": "Test",
                                        "description": "This is just a test order for SuperClient",
                                        "team": { "id": 2 }
                                    }
                                )
                                    .expectStatus(200)
                                    .afterJSON(function () {
                                        frisby.create('Old parent free budget should be changed')
                                            .get(url + '/order/' + parentOrder.id)
                                            .expectStatus(200)
                                            .expectJSON({'free_budget': 600})
                                            .toss();
                                        frisby.create('New parent free budget should be changed')
                                            .get(url + '/order/' + newParent.id)
                                            .expectStatus(200)
                                            .expectJSON({'free_budget': 900})
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

frisby.create('Create parent order')
    .post(
    url + '/orders',
    {
        "invoiced_budget": 1000.00,
        "allocatable_budget": 600.00,
        "name": "Test",
        "description": "This is just a test order for SuperClient",
        "team": {
            "id": 1
        }
    }
)
    .expectStatus(201)
    .afterJSON(function (parentOrder) {
        frisby.create('Create order')
            .post(
            url + '/orders',
            {
                "invoiced_budget": 1000.00,
                "allocatable_budget": 1000.00,
                "name": "Test",
                "description": "This is just a test order for SuperClient",
                "team": {"id": 2}
            }
        )
            .expectStatus(201)
            .afterJSON(function (childOrder) {
                frisby.create('Set child order parent should fail because child.invoiced_budget > parent.free_budget')
                    .put(
                    url + '/order/' + childOrder.id,
                    {
                        "parent_id": parentOrder.id,
                        "invoiced_budget": 10000.00,
                        "allocatable_budget": 10000.00,
                        "name": "Test",
                        "description": "This is just a test order for SuperClient",
                        "team": {"id": 2}
                    }
                )
                    .expectStatus(422)
                    .expectJSON({errors: ['Suborder can not be invoiced more than parent free budget']})
                    .toss();

                frisby.create('Set child order parent should fail because child.internal_order')
                    .put(
                    url + '/order/' + childOrder.id,
                    {
                        "parent_id": parentOrder.id,
                        "internal_order": true,
                        "invoiced_budget": 100.00,
                        "allocatable_budget": 100.00,
                        "name": "Test",
                        "description": "This is just a test order for SuperClient",
                        "team": {"id": 2}
                    }
                )
                    .expectStatus(422)
                    .expectJSON({errors: ['Order is set as Internal - can not change parent order']})
                    .toss();

                frisby.create('Correct invoice')
                    .post(url + '/invoices',
                    {
                        "external_id": Math.floor(Math.random() * (99999 - 1)) + 30
                    })
                    .expectStatus(201)
                    .afterJSON(function(invoice){
                        frisby.create('Invoice order with correct invoice')
                            .post(url + '/order/' + childOrder.id + '/invoice', {'invoice_id' : invoice.id})
                            .expectStatus(200)
                            .toss();

                        frisby.create('Set child order parent should fail because child.invoice')
                            .put(
                            url + '/order/' + childOrder.id,
                            {
                                "parent_id": parentOrder.id,
                                "invoiced_budget": 100.00,
                                "allocatable_budget": 100.00,
                                "name": "Test",
                                "description": "This is just a test order for SuperClient",
                                "team": {"id": 2}
                            }
                        )
                            .expectStatus(422)
                            .expectJSON({errors: ['Order has invoice linked - can not change parent order']})
                            .toss();
                    })
                    .toss();
            })
            .toss();
    })
    .toss();

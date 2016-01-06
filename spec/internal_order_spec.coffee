config = require './config'
url = config.url

frisby.create('Create Order: set allocatable budget equal to invoiced')
  .post url + '/orders',
      "invoiced_budget": 150.00,
      "allocatable_budget": 150.00,
      "name" : "Test",
      "description" : "This is just a test order for SuperClient",
      "team":
        "id" : 1
      "internal_order" : true
    .expectStatus(201)
    .afterJSON (order)->
      frisby.create 'Order should be paid'
        .get url + '/order/' + order.id
        .expectStatus 200
        .afterJSON (new_order)->
          expect(new_order.paid).toBe true
          expect(new_order.internal_order).toBe true
          frisby.create 'Order can be make non internal'
            .delete url + '/order/' + new_order.id + '/internal'
            .expectStatus 200
            .afterJSON (non_internal_order)->
              frisby.create 'Order should be un paid and non internal'
                .get url + '/order/' + order.id
                .expectStatus 200
                .afterJSON (updated_order)->
                  expect(updated_order.paid).toBe false
                  expect(updated_order.internal_order).toBe false
                .toss()
            .toss()
        .toss()
    .toss()

frisby.create 'Correct invoice' 
  .post url + '/invoices',
    "external_id": Math.floor(Math.random() * (99999 - 1)) + 30
  .expectStatus(201)
  .afterJSON (invoice)->
    frisby.create('Correct order creation')
      .post url + '/orders',
        "invoiced_budget": 150.00,
        "allocatable_budget": 100.00,
        "name" : "Test",
        "description" : "This is just a test order for SuperClient",
        'paid' : true
        "team":  
          "id" : 1
      .expectStatus(201)
      .afterJSON (order)->
         frisby.create('Invoice order with correct invoice')
           .post(url + '/order/' + order.id + '/invoice', {'invoice_id' : invoice.id})
           .expectStatus(200)
           .afterJSON (response)->
             frisby.create "can't make order with invoice internal"
               .post url + '/order/' + order.id + '/internal'
               .expectStatus(422)
               .expectJSON({errors: ["Internal order can't have invoice"]})
               .toss()
           .toss()
      .toss()
  .toss()

frisby.create('Create Order: set allocatable budget equal to invoiced')
  .post url + '/orders',
    "invoiced_budget": 150.00,
    "allocatable_budget": 150.00,
    "name" : "Test",
    "description" : "This is just a test order for SuperClient",
    "team":
      "id" : 1
    "internal_order" : true
  .expectStatus(201)
  .afterJSON (order)->
    frisby.create 'Order should be paid'
      .get url + '/order/' + order.id
      .expectStatus 200
      .afterJSON (new_order)->
        expect(new_order.paid).toBe true
        expect(new_order.internal_order).toBe true
        frisby.create "Complete internal order"
          .post url + '/order/' + new_order.id + '/complete'
          .expectStatus 200
          .afterJSON (order)->
            frisby.create "internal order can complete with rules"
              .get url + '/transactions?limit=99999'
              .expectStatus 200
              .afterJSON (transactions)->
                expect(transactions.length).toBe 3
                manager_transactions = []
                team_transactions = []
                transactions.forEach (tr)->
                  team_transactions.push(tr) if tr.owner.type == 'team'
                transactions.forEach (tr)->
                  manager_transactions.push(tr) if tr.owner.type == 'user'
                expect(manager_transactions[0].comment).toBe "Order #" + order.id + " was completed"
                expect(team_transactions[0].comment).toBe "Order #" + order.id + " was completed"
                expect(team_transactions.length).toBe 2
                expect(manager_transactions.length).toBe 1
                expect(team_transactions[0].total).toBe '150.0'
                expect(team_transactions[1].comment).toBe "Order #" + order.id + " was completed"
                expect(team_transactions[1].total).toBe '-150.0'
              .toss()
          .toss()
      .toss()
  .toss()

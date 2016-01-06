config = require './config'
url = config.url

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
           .toss()
         frisby.create('Set order paid')
           .post url + '/invoice/' + invoice.id + '/paid'
           .expectStatus(200)
           .toss()
         frisby.create('Get current Transactions')
           .get(url + '/transactions/?limit=9999999')
           .expectStatus(200)
           .afterJSON (transactionsBefore)->
             expect(transactionsBefore.length == 0).toBe true
             frisby.create('Set order comlete')
               .post url + '/order/' + order.id + '/complete'
               .expectStatus(200)
               .toss()
             frisby.create('Get transactions after order comlete')
               .get url + '/transactions/?limit=999999'
               .expectStatus(200)
               .afterJSON (transactionsAfter)->
                 expect(transactionsAfter.length - transactionsBefore.length == 6).toBe true
                 balance_manager = []
                 balance_central = []
                 payment_central = []
                 balance_manager_2 = []
                 payment_team = []
                 transactionsAfter.forEach (tr)->
                   balance_manager.push tr if tr.owner.name == 'Manager1' && tr.type == 'balance' && tr.comment.match /Central/
                   balance_central.push tr if tr.owner.name == 'Central Office' && tr.type == 'balance'
                   payment_central.push tr if tr.owner.name == 'Central Office' && tr.type == 'payment'
                   balance_manager_2.push tr if tr.owner.name == 'Manager1' && tr.type == 'balance' && !tr.comment.match /Central/
                   payment_team.push tr if tr.owner.name == 'OpsWay1' && tr.type == 'payment'
                 expect(balance_manager[0].total).toBe '-60.0'
                 expect(balance_manager[0].comment).toBe 'Order #' + order.id + ' was completed: Central office fee'
                 expect(balance_central[0].total).toBe '60.0'
                 expect(balance_central[0].comment).toBe 'Order #' + order.id + ' was completed: Central office fee'
                 expect(payment_central[0].total).toBe '150.0'
                 expect(payment_central[0].comment).toBe 'Order #' + order.id + ' was completed: Central office fee'
                 expect(balance_manager_2[0].total).toBe '150.0'
                 expect(balance_manager_2[0].comment).toBe 'Order #' + order.id + ' was completed'
                 expect(payment_team[0].total).toBe '150.0'
                 expect(payment_team[0].comment).toBe 'Order #' + order.id + ' was completed'
            
               .toss()
           .toss()
      .toss()
  .toss()

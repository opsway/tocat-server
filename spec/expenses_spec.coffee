config = require './config'
url = config.url
task01 = 'opsway_1111'

frisby.create('Correct task creation')
 .post(url + '/tasks', {"external_id": task01 })
 .expectStatus(201)
 .afterJSON (task)->
    frisby.create('Initial task settings')
      .get(url + '/task/' + task.id)
      .expectStatus(200)
      .expectJSON({'budget' : 0, 'paid' : false, 'resolver' : {}, 'accepted' : false, 'external_id' : task01 })
      .afterJSON ->
        frisby.create 'Work with expenses'
          .post url + '/task/' + task.id + '/expenses'
          .expectStatus(200)
          .afterJSON (expense)->
            frisby.create 'Can remove taks expenses flag'
              .delete(url + '/task/' + task.id + '/expenses')
              .expectStatus 200
              .toss()
          .toss()
      .toss()
 .toss() 

  
frisby.create('Correct invoice creation')
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
          "team":  
              "id" : 2
      .expectStatus(201)
      .afterJSON (order)-> 
        frisby.create('Correct task creation')
          .post(url + '/tasks', {"external_id": task01 + 'aa', order_id: order.id })
          .expectStatus(201)
          .afterJSON (task)->
            frisby.create('Invoice order with correct invoice')
              .post(url + '/order/' + order.id + '/invoice', {'invoice_id' : invoice.id})
              .expectStatus(200)
              .toss();
            frisby.create('Set task budgets')
              .post url + '/task/' + task.id + '/budget', {budget: [{order_id: order.id, budget: 30}]}
              .expectStatus(200)
              .toss()
            frisby.create('Work with expenses')
              .post url + '/task/' + task.id + '/expenses'
              .expectStatus(200)
              .toss()
            frisby.create('Set invoice paid')
              .post(url + '/invoice/' + invoice.id + '/paid')
              .expectStatus(200)
              .toss()
            frisby.create('Set task accepted')
              .post url + '/task/' + task.id + '/accept'
              .expectStatus(200)
              .toss()
            frisby.create('Complete order')
              .post url + '/order/' + order.id + '/complete' 
              .expectStatus(200)
              .afterJSON ->
                frisby.create('Check transactions for expenses task')
                  .get url + '/transactions?limit=9999'
                  .expectStatus 200
                  .afterJSON (transactions)->
                    expense_transactions = []
                    transactions.forEach (tr)->
                      if tr.comment.match /Expense/
                        expense_transactions.push tr 
                    expect(transactions.length).toBe 7
                    expect(expense_transactions.length).toBe 1
                    expect(expense_transactions[0].comment).toBe "Expense, Issue #" + task01 + 'aa'
                    expect(expense_transactions[0].total).toBe '-30.0'
                    expect(expense_transactions[0].type).toBe 'payment'
                  .toss()
              .toss()
          .toss()
      .toss()
  .toss()

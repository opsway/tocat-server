var config = require('./config');
var url = config.url;

frisby.create('Correct invoice')
    .post(url + '/invoices',
    {
        "external_id": '67899000000303011' + Math.floor(Math.random() * 1000000)
    })
    .expectStatus(201)
    .afterJSON(function(invoice){

              frisby.create('Invoice order id=1 with correct invoice. Order is hardcoded in import.sql')
                .post(url + '/order/1/invoice', {'invoice_id' : invoice.id})
                .expectStatus(200)
                .toss();

              frisby.create('Set invoice paid')
                .post(url + '/invoice/' + invoice.id + '/paid')
                .expectStatus(200)
                .toss();
    
              frisby.create('Check that order is paid')
                .get(url + '/order/1')
                .expectStatus(200)
                .expectJSON({'paid' : true})
                .toss();
            
              frisby.create('Expecting task 1 (hardcoded) to be paid')
                .get(url + '/task/1')
                .expectStatus(200)
                .inspectBody()
                .expectJSON({'paid' : true})
                .toss();

            //TODO: Check that team2 tx created, check that user1 tx created
    })
    .toss();

var config = require('./config');
var url = config.url;
		                 	    frisby.create('Set task budgets')
    		                   		.post(url + '/task/92/' + '/budget', { budget : [{order_id : '11' , budget   : 100 }]}, {json: true})
    		                   		.expectStatus(200)
    		                   		.toss();
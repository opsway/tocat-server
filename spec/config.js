exports.url = 'http://localhost:3001';
frisby = require('frisby');

frisby.globalSetup({
 request: {
 	json : true
 },
  timeout: (30 * 1000)
});

exports.frisby = frisby;

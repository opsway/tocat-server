exports.url = 'http://localhost:3000';
frisby = require('frisby');

frisby.globalSetup({
 request: {
 	json : false
 },
  timeout: (30 * 1000)
});

exports.frisby = frisby;

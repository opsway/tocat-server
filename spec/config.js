exports.url = 'http://test.tocat.opsway.com';
frisby = require('frisby');

frisby.globalSetup({
 request: {
 	json : false
 },
  timeout: (30 * 1000)
});

exports.frisby = frisby;

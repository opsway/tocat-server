//exports.url = 'http://test.tocat.opsway.com';
exports.url = 'http://localhost:3005';
frisby = require('frisby');

frisby.globalSetup({
 request: {
 	json : false
 },
  timeout: (30 * 1000)
});

exports.frisby = frisby;

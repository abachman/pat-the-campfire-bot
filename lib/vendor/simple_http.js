(function() {
  var http, _;
  http = require('http');
  _ = require('underscore')._;
  module.exports = {
    curl: function(options, callback) {
      var client, request;
      options = _.defaults(options, {
        method: 'GET',
        port: 80
      });
      client = http.createClient(options.port, options.host);
      request = client.request(options.method, options.path, {
        host: options.host
      });
      request.end();
      return request.on('response', function(response) {
        var data;
        data = '';
        response.on('data', function(chunk) {
          return data += chunk;
        });
        return response.on('end', function() {
          return callback(data);
        });
      });
    }
  };
}).call(this);

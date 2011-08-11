(function() {
  var curl, qs;
  qs = require('querystring');
  curl = require('../vendor/simple_http').curl;
  module.exports = {
    name: "It's This For That",
    listen: function(message, room, logger) {
      var body, options;
      body = message.body;
      if ((/pat/i.test(body) && (/a business/i.test(body) || /business idea/i.test(body))) || /^!biz/.test(body)) {
        console.log("finding a new business idea");
        options = {
          host: 'itsthisforthat.com',
          path: '/api.php?text'
        };
        return curl(options, function(data) {
          if (data.length) {
            return room.speak(data.trim(), logger);
          }
        });
      }
    }
  };
}).call(this);

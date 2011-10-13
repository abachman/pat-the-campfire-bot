(function() {
  var SpeakOnce, echo_matcher, qs;
  SpeakOnce = require('../vendor/speak_once').SpeakOnce;
  qs = require('querystring');
  echo_matcher = /^!echo\b(.*)/i;
  module.exports = {
    name: "echo",
    http_listen: function(request, response, logger) {
      var data;
      if (/\/say/i.test(request.url)) {
        if (/post/i.test(request.method)) {
          data = "";
          request.on('data', function(incoming) {
            return data += incoming;
          });
          return request.on('end', function() {
            var message;
            message = qs.parse(data).message;
            console.log("[echo] recieved data (" + (typeof message) + "): " + message);
            response.writeHead(200, {
              'Content-Type': 'text/plain'
            });
            new SpeakOnce(function(room) {
              return room.speak(message);
            });
            return response.end('');
          });
        }
      }
    },
    listen: function(message, room, logger) {
      var body;
      body = message.body;
      if (echo_matcher.test(body)) {
        console.log("echoing");
        return room.speak(echo_matcher.exec(body)[1], logger);
      }
    }
  };
}).call(this);

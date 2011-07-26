(function() {
  var anagrammit_host, anagrammit_port, anagrammit_token, http, qs, util;
  http = require('http');
  util = require('util');
  qs = require('querystring');
  anagrammit_token = process.env.ANAGRAMMIT_API_TOKEN || 'dev';
  anagrammit_host = process.env.ANAGRAMMIT_HOST || 'localhost';
  anagrammit_port = process.env.ANAGRAMMIT_PORT || 3000;
  module.exports = {
    listen: function(message, room, logger) {
      var anagrammit_client, body, options, phrase, request;
      body = message.body;
      console.log("checking anagrammability");
      if (/pat/i.test(body) && /anagram/i.test(body)) {
        phrase = body.match(/"([^\"]+)"/)[1];
        console.log("getting anagrams of \"" + phrase + "\"");
        if (phrase.length) {
          anagrammit_client = http.createClient(anagrammit_port, anagrammit_host);
          options = {
            method: 'GET',
            path: "/generate?phrase=" + (qs.escape(phrase)) + "&token=" + (qs.escape(anagrammit_token))
          };
          request = anagrammit_client.request(options.method, options.path);
          request.end();
          return request.on('response', function(response) {
            var data;
            data = '';
            response.on('data', function(chunk) {
              return data += chunk;
            });
            return response.on('end', function() {
              var results;
              results = JSON.parse(data);
              if (/success/i.test(results.status)) {
                room.speak("" + results.results.length + " results:");
                return room.speak(results.results.join('\n'), logger);
              } else {
                return room.speak("there was a problem :( \"" + results.message + "\"", logger);
              }
            });
          });
        } else {
          return room.speak("you'll have to give me more than that", logger);
        }
      }
    }
  };
}).call(this);

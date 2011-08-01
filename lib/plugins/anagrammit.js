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
      if (/pat/i.test(body) && /anagram/i.test(body)) {
        phrase = body.match(/"([^\"]*)"/);
        if (!(phrase && phrase[1].length)) {
          room.speak("You'll have to give me more than that. Make sure you include a phrase in double quotes. e.g.,  \"helloworld\"", logger);
          return;
        }
        phrase = phrase[1];
        console.log("getting anagrams of \"" + phrase + "\"");
        console.log("from " + anagrammit_host + ":" + anagrammit_port + "/token=" + anagrammit_token);
        anagrammit_client = http.createClient(anagrammit_port, anagrammit_host);
        options = {
          method: 'GET',
          path: "/generate?phrase=" + (qs.escape(phrase)) + "&token=" + (qs.escape(anagrammit_token))
        };
        request = anagrammit_client.request(options.method, options.path, {
          host: anagrammit_host
        });
        request.end();
        return request.on('response', function(response) {
          var data;
          data = '';
          response.on('data', function(chunk) {
            console.log("chunk: " + chunk);
            return data += chunk;
          });
          return response.on('end', function() {
            var results;
            console.log("results are ready! " + data);
            results = JSON.parse(data);
            if (/success/i.test(results.status)) {
              room.speak("" + results.results.length + " results:");
              return room.paste(results.results.join(' \n'), logger);
            } else {
              return room.speak("there was a problem :( \"" + results.message + "\"", logger);
            }
          });
        });
      }
    }
  };
}).call(this);

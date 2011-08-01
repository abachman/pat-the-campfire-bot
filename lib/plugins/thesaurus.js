(function() {
  var http, qs, thesaurus_host, thesaurus_port, thesaurus_token, util, _;
  http = require('http');
  util = require('util');
  _ = require('underscore')._;
  qs = require('querystring');
  thesaurus_token = process.env.THESAURUS_API_TOKEN;
  thesaurus_host = 'words.bighugelabs.com';
  thesaurus_port = 80;
  module.exports = {
    listen: function(message, room, logger) {
      var body, form_template, options, phrase, request, thesaurus_client;
      body = message.body;
      if (!thesaurus_token) {
        return;
      }
      if (/pat/i.test(body) && (/thesaurus/i.test(body) || /another word for/i.test(body) || /synonym/i.test(body))) {
        phrase = body.match(/"([^\"]*)"/);
        if (!(phrase && phrase[1].length)) {
          room.speak("You'll have to give me more than that. Make sure you include a word in double quotes. e.g.,  \"helloworld\"", logger);
          return;
        }
        phrase = phrase[1];
        console.log("getting synonyms of \"" + phrase + "\"");
        console.log("from " + thesaurus_host + ":" + thesaurus_port + "/api/2/" + (qs.escape(thesaurus_token)) + "/" + (qs.escape(phrase)) + "/json");
        form_template = _.template("<%= form %>: <%= results %>");
        thesaurus_client = http.createClient(thesaurus_port, thesaurus_host);
        options = {
          method: 'GET',
          path: "/api/2/" + (qs.escape(thesaurus_token)) + "/" + (qs.escape(phrase)) + "/json"
        };
        request = thesaurus_client.request(options.method, options.path, {
          host: thesaurus_host
        });
        request.end();
        return request.on('response', function(response) {
          var data;
          data = '';
          response.on('data', function(chunk) {
            return data += chunk;
          });
          return response.on('end', function() {
            var out, results, _forms;
            try {
              results = JSON.parse(data);
              out = "";
              _forms = _.keys(results);
              _forms.forEach(function(form) {
                if (results[form].syn.length) {
                  out += form_template({
                    form: form,
                    results: results[form].syn.join(", ")
                  });
                  return out += "\n\n";
                }
              });
              if (out.length) {
                room.speak("\"" + phrase + "\"");
                return room.paste(out, logger);
              } else {
                return room.speak("I didn't get any results for " + phrase);
              }
            } catch (e) {
              return room.speak("there was a problem :( \"" + e.message + "\"", logger);
            }
          });
        });
      }
    }
  };
}).call(this);

(function() {
  var curl, qs, thesaurus_host, thesaurus_token, util, _;
  util = require('util');
  _ = require('underscore')._;
  qs = require('querystring');
  curl = require('../vendor/simple_http').curl;
  thesaurus_token = process.env.THESAURUS_API_TOKEN;
  thesaurus_host = 'words.bighugelabs.com';
  module.exports = {
    name: "Thesaurus",
    listen: function(message, room, logger) {
      var body, ending_phrase, form_template, options, phrase, quoted_phrase;
      body = message.body;
      if (!thesaurus_token) {
        return;
      }
      if (/pat/i.test(body) && (/thesaurus/i.test(body) || /another word for/i.test(body) || /synonym/i.test(body))) {
        quoted_phrase = body.match(/"([^\"]*)"/);
        ending_phrase = body.match(/([a-z]+)[ ?]*$/i);
        phrase = quoted_phrase || ending_phrase;
        if (!(phrase && phrase[1].length)) {
          room.speak("I can't tell what you want me to look up :(", logger);
          return;
        }
        phrase = phrase[1];
        console.log("getting synonyms of \"" + phrase + "\"");
        console.log("from " + thesaurus_host + "/api/2/" + (qs.escape(thesaurus_token)) + "/" + (qs.escape(phrase)) + "/json");
        form_template = _.template("<%= form %>: <%= results %>");
        options = {
          host: thesaurus_host,
          path: "/api/2/" + (qs.escape(thesaurus_token)) + "/" + (qs.escape(phrase)) + "/json"
        };
        return curl(options, function(data) {
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
      }
    }
  };
}).call(this);

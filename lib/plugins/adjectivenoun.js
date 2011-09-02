(function() {
  var adjectivenoun_host, adjectivenoun_port, curl, qs, util;
  util = require('util');
  curl = require('../vendor/simple_http').curl;
  qs = require('querystring');
  adjectivenoun_host = 'adjectivenoun.me';
  adjectivenoun_port = 80;
  module.exports = {
    name: "Anagrammit",
    listen: function(message, room, logger) {
      var body, commit_matcher, hash, options;
      body = message.body;
      commit_matcher = /commit\/([a-z0-9]+)\)/;
      if (commit_matcher.test(body)) {
        hash = commit_matcher.exec(body)[1];
        if (!(hash && hash.length)) {
          return;
        }
        console.log("getting adjectivenoun for \"" + hash + "\"");
        options = {
          host: adjectivenoun_host,
          port: adjectivenoun_port,
          path: "/" + hash + ".txt"
        };
        return curl(options, function(data) {
          console.log("got a response from adjective noun: \"" + data + "\"");
          return room.speak("\"" + (data.trim()) + "\"");
        });
      }
    }
  };
}).call(this);

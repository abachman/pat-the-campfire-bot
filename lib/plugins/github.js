(function() {
  var AdjectiveNoun, SpeakOnce, curl, qs, util, _;
  util = require('util');
  curl = require('../vendor/simple_http').curl;
  SpeakOnce = require('../vendor/speak_once').SpeakOnce;
  _ = require('underscore')._;
  qs = require('querystring');
  AdjectiveNoun = (function() {
    function AdjectiveNoun() {}
    AdjectiveNoun.prototype.get = function(phrase, callback) {
      var options;
      options = {
        host: 'adjectivenoun.me',
        port: 80,
        path: "/" + phrase + ".txt"
      };
      return curl(options, function(data) {
        return callback(data.trim());
      });
    };
    return AdjectiveNoun;
  })();
  module.exports = {
    name: "Github",
    http_listen: function(request, response, logger) {
      var data;
      if (/\/commit/i.test(request.url)) {
        if (/get/i.test(request.method)) {
          if (process.env.node_env !== 'production') {
            response.writeHead(200, {
              'Content-Type': 'text/html'
            });
            response.end("            <form action='/commit' method='post'>              <textarea rows='40' cols='80' id='payload' name='payload'></textarea>              <br />              <input type='submit' value='post' />            </form>          ");
            return true;
          } else {
            return false;
          }
        }
        data = "";
        request.on('data', function(incoming) {
          return data += incoming;
        });
        request.on('end', function() {
          var after, after_token, before, before_token, branch, commit, hash_token, link_to_commit, payload, project, qty;
          payload = qs.parse(data).payload;
          console.log("[github] recieved data (" + (typeof payload) + "): " + payload);
          response.writeHead(200, {
            'Content-Type': 'text/plain'
          });
          commit = null;
          try {
            commit = JSON.parse(payload);
          } catch (e) {
            console.log("[github] error parsing commit data, bailing. :(");
            console.log("[github] " + e.message);
            return false;
          }
          try {
            hash_token = /^(.{7})/;
            before = commit.before;
            before_token = hash_token.exec(before)[1];
            after = commit.after;
            after_token = hash_token.exec(after)[1];
            qty = commit.commits.length;
            project = commit.repository.name;
            branch = /\/([^/]*)$/.exec(commit.ref)[1];
            link_to_commit = function(hash) {
              return commit.repository.url + ("/commit/" + hash);
            };
            console.log("[github] parsed commit " + commit.repository.url + "/commit/" + after_token);
            (new AdjectiveNoun).get(after_token, function(release_name) {
              return new SpeakOnce(function(room) {
                var c, compare_url;
                try {
                  if (qty === 1) {
                    c = commit.commits[0];
                    return room.speak("[" + project + "/" + branch + "] " + c.message + " - " + c.author.name + " (" + (link_to_commit(after)) + ") \n\ncurrent release " + after_token + ": \"" + release_name + "\"", logger);
                  } else if (qty > 1) {
                    compare_url = commit.compare;
                    room.speak("[" + project + "] " + commit.pusher.name + " pushed " + qty + " commits to " + branch + ": " + compare_url);
                    commit.commits.forEach(function(c) {
                      return room.speak("[" + project + "/" + branch + "] " + c.message + " - " + c.author.name, logger);
                    });
                    return room.speak("[" + project + "/" + branch + "] current release " + after_token + ": \"" + release_name + "\"");
                  }
                } catch (ex) {
                  return console.log("error trying to post github commit: " + ex.message);
                }
              });
            });
            response.end('');
          } catch (ex) {
            console.log("[github] ERROR: " + ex.message);
            response.end(ex.message);
          }
          return true;
        });
        return true;
      }
    },
    listen: function(message, room, logger) {
      var body, commit_matcher, hash;
      body = message.body;
      commit_matcher = /commit\/([a-z0-9]+)\)/;
      if (commit_matcher.test(body)) {
        hash = commit_matcher.exec(body)[1];
        if (!(hash && hash.length)) {
          return;
        }
        console.log("getting adjectivenoun for \"" + hash + "\"");
        return (new AdjectiveNoun).get(hash, function(data) {
          console.log("got a response from adjective noun: \"" + data + "\"");
          return room.speak("\"" + data + "\"");
        });
      }
    }
  };
}).call(this);

(function() {
  var AdjectiveNoun, Campfire, curl, qs, util, _;
  util = require('util');
  curl = require('../vendor/simple_http').curl;
  Campfire = require('../vendor/campfire').Campfire;
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
      var commit;
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
        commit = [];
        request.on('data', function(data) {
          return commit.push(data);
        });
        request.on('end', function() {
          commit = commit.join();
          console.log("[github] recieved data:\n" + (qs.parse(commit).payload));
          response.writeHead(200, {
            'Content-Type': 'text/plain'
          });
          try {
            commit = JSON.parse(qs.parse(commit).payload);
            (new AdjectiveNoun).get(commit.after, function(release_name) {
              var campfire;
              campfire = new Campfire({
                ssl: true,
                token: process.env.campfire_bot_token,
                account: process.env.campfire_bot_account
              });
              return campfire.room(process.env.campfire_bot_room, function(room) {
                var after, before, branch, c, compare_url, project, qty;
                try {
                  qty = commit.commits.length;
                  project = commit.repository.name;
                  branch = /\/([^/]*)$/.exec(commit.ref)[1];
                  before = commit.before;
                  after = commit.after;
                  if (qty === 1) {
                    c = commit.commits[0];
                    return room.speak("[" + project + "/" + branch + "] " + c.message + " - " + c.author.name + " \n\n\"" + release_name + "\"", logger);
                  } else if (qty > 1) {
                    compare_url = "" + commit.repository.url + "/compare/" + before + "..." + after;
                    room.speak("[" + project + "] " + commit.repository.owner.name + " pushed " + qty + " commits to " + branch + ": " + compare_url);
                    commit.commits.forEach(function(c) {
                      return room.speak("[" + project + "/" + branch + "] " + c.message + " - " + c.author.name, logger);
                    });
                    return room.speak("[" + project + "/" + branch + "] \"" + release_name + "\"");
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

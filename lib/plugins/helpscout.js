// Generated by CoffeeScript 1.8.0
(function() {
  var HelpScout, HelpScoutAPI, https, _;

  _ = require('underscore')._;

  https = require('https');

  HelpScoutAPI = (function() {
    HelpScoutAPI.prototype.hostname = "api.helpscout.net";

    function HelpScoutAPI(config) {
      this.config = config;
    }

    HelpScoutAPI.prototype.get = function(options, callback) {
      var request;
      request = https.request(options, function(response) {
        var data;
        data = '';
        response.on('data', function(chunk) {
          return data += chunk;
        });
        response.on('end', function() {
          var e, results;
          console.log("GOT end EVENT ON HelpScout API with " + data.length + " bytes of data");
          try {
            results = JSON.parse(data);
            return callback(results);
          } catch (_error) {
            e = _error;
            console.log("Failed to parse HelpScout API response on end: " + e.message);
            return callback(null);
          }
        });
        return response.on('close', function() {
          var e, results;
          console.log("GOT close EVENT ON HelpScout API!");
          try {
            results = JSON.parse(data);
            return callback(results);
          } catch (_error) {
            e = _error;
            console.log("Failed to parse HelpScout API response on close: " + e.message);
            return callback(null);
          }
        });
      });
      request.end();
      return request.on('error', function(e) {
        console.error(e);
        return callback(null);
      });
    };

    HelpScoutAPI.prototype.get_conversation_by_number = function(number, callback) {
      var options;
      options = {
        host: this.hostname,
        port: 443,
        path: "/v1/conversations/number/" + number + ".json",
        headers: {
          'Authorization': 'Basic ' + new Buffer("" + this.config.helpscout_api_key + ":X").toString('base64')
        }
      };
      return this.get(options, callback);
    };

    return HelpScoutAPI;

  })();

  HelpScout = (function() {
    HelpScout.prototype.name = "HelpScout";

    HelpScout.prototype.room_number_matcher = /(^|[^a-zA-Z0-9])[\/](\d+)($|[^a-zA-Z0-9])/;

    HelpScout.prototype.link_message = _.template("[<%= mailbox.name %>] <%= subject %> - <%= customer.email %>\n https://secure.helpscout.net/conversation/<%= id %>/<%= number %>/ <% if (tags != null) { %>(<%= tags.join(', ') %>)<% } %>".replace(/^\s+|\s+$/gm, ''));

    function HelpScout() {
      this.api = new HelpScoutAPI({
        helpscout_api_key: process.env.helpscout_api_key
      });
    }

    HelpScout.prototype.link_to_ticket = function(message, room, logger) {
      var request_id;
      request_id = this.room_number_matcher.exec(message)[2];
      return this.api.get_conversation_by_number(request_id, (function(_this) {
        return function(results) {
          if ((results != null) && (results.item != null)) {
            return room.speak(_this.link_message(results.item), logger);
          }
        };
      })(this));
    };

    HelpScout.prototype.listen = function(msg, room, logger) {
      var body;
      body = msg.body;
      if (this.room_number_matcher.test(body)) {
        console.log("posting helpscout link: " + (this.room_number_matcher.exec(msg.body)[2]));
        return this.link_to_ticket(body, room, logger);
      }
    };

    return HelpScout;

  })();

  module.exports = new HelpScout;

}).call(this);

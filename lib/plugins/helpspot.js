(function() {
  var DomJS, Helpspot, HelpspotAPI, find_child_by_name, http, logger, querystring, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ = require('underscore')._;
  http = require('http');
  querystring = require('querystring');
  DomJS = require('dom-js').DomJS;
  find_child_by_name = function(_dom, name) {
    var child, result, _i, _len, _ref;
    if (name === _dom.name) {
      return _dom;
    } else if (_dom.children && _dom.children.length > 0) {
      _ref = _dom.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        result = find_child_by_name(child, name);
        if (result != null) {
          return result;
        }
      }
    }
  };
  logger = function(d) {
    try {
      return console.log("" + d.message.created_at + ": " + d.message.body);
    } catch (_e) {}
  };
  HelpspotAPI = (function() {
    function HelpspotAPI(config) {
      this.config = config;
    }
    HelpspotAPI.prototype.get_request = function(request_id, callback) {
      var api_client, options, query, request;
      api_client = http.createClient(80, this.config.helpspot_hostname);
      query = querystring.stringify({
        method: 'private.request.get',
        xRequest: request_id,
        output: 'json',
        username: this.config.helpspot_username,
        password: this.config.helpspot_password
      });
      options = {
        method: 'GET',
        path: this.config.helpspot_path + "/api/index.php?" + query
      };
      request = api_client.request(options.method, options.path, {
        host: this.config.helpspot_hostname
      });
      request.end();
      return request.on('response', function(response) {
        var data;
        data = '';
        response.on('data', function(chunk) {
          return data += chunk;
        });
        response.on('end', function() {
          var results;
          console.log("GOT end EVENT ON HELPSPOT API!");
          try {
            results = JSON.parse(data);
            return callback(results);
          } catch (e) {
            return console.log("Failed to parse Helpspot API response on end: " + e.message);
          }
        });
        return response.on('close', function() {
          var results;
          console.log("GOT close EVENT ON HELPSPOT API!");
          try {
            results = JSON.parse(data);
            return callback(results);
          } catch (e) {
            return console.log("Failed to parse Helpspot API response on close: " + e.message);
          }
        });
      });
    };
    return HelpspotAPI;
  })();
  Helpspot = (function() {
    Helpspot.prototype.name = "Helpspot";
    function Helpspot() {
      this.room_id_matcher = /(^|[^a-zA-Z0-9])(\d{5})($|[^a-zA-Z0-9])/;
      this.room_link_template = process.env.helpspot_link_template;
      this.api = new HelpspotAPI({
        helpspot_hostname: process.env.helpspot_hostname,
        helpspot_path: process.env.helpspot_path,
        helpspot_username: process.env.helpspot_username,
        helpspot_password: process.env.helpspot_password
      });
    }
    Helpspot.prototype.link_to_ticket = function(message, room) {
      var request_id;
      request_id = this.room_id_matcher.exec(message)[2];
      return this.api.get_request(request_id, __bind(function(results) {
        var link;
        if (results && results.xRequest === request_id) {
          console.log("I got results from Helpspot, speaking...");
          link = ("[" + results.xCategory + "] " + results.sTitle + " \n") + this.room_link_template.replace('$', request_id);
          return room.speak("" + link, logger);
        }
      }, this));
    };
    Helpspot.prototype.ticket_status = function(message, room) {
      var request_id;
      request_id = this.room_id_matcher.exec(message)[2];
      return this.api.get_request(request_id, __bind(function(request) {
        var link, out;
        if (request && request.xRequest === request_id) {
          link = this.room_link_template.replace('$', request_id);
          out = "" + link + " \n\n";
          out += "assigned to: " + (request.xPersonAssignedTo.split(' ')[0]) + " \n";
          out += "from:        " + request.fullname + " \n";
          out += "subject:     " + request.sTitle + " \n";
          out += "category:    " + request.xCategory + " \n";
          out += "status:      " + request.xStatus + " \n";
          out += "opened:      " + request.dtGMTOpened + " \n";
          if (request.dtGMTClosed && request.dtGMTClosed.length) {
            out += "closed:      " + request.dtGMTClosed + " \n";
          }
          return room.paste(out, logger);
        } else {
          return room.speak("I couldn't find a ticket with id: " + request_id, logger);
        }
      }, this));
    };
    Helpspot.prototype.listen = function(msg, room, env) {
      var body;
      body = msg.body;
      if (!((this.api.config.helpspot_hostname != null) && (this.api.config.helpspot_path != null) && (this.api.config.helpspot_username != null) && (this.api.config.helpspot_password != null))) {
        return;
      }
      if (this.room_id_matcher.test(body)) {
        if (/pat/i.test(body) && /status/i.test(body)) {
          console.log("getting helpspot status: " + (this.room_id_matcher.exec(msg.body)[2]));
          return this.ticket_status(body, room);
        } else {
          console.log("posting helpspot link: " + (this.room_id_matcher.exec(msg.body)[2]));
          return this.link_to_ticket(body, room);
        }
      }
    };
    return Helpspot;
  })();
  module.exports = new Helpspot;
}).call(this);

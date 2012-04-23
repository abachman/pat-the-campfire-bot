(function() {
  var SpeakOnce, curl, qs, util, _;
  util = require('util');
  curl = require('../vendor/simple_http').curl;
  SpeakOnce = require('../vendor/speak_once').SpeakOnce;
  _ = require('underscore')._;
  qs = require('querystring');
  module.exports = {
    name: "Logentries",
    http_listen: function(request, response, logger) {
      var data;
      if (/\/logentries/i.test(request.url)) {
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
          var imcoming, incoming, payload;
          payload = qs.parse(data).payload;
          console.log("[logentries] recieved data stream (" + (typeof data) + "): " + data);
          console.log("[logentries] recieved payload (" + (typeof payload) + "): " + payload);
          response.writeHead(200, {
            'Content-Type': 'text/plain'
          });
          imcoming = null;
          try {
            incoming = JSON.parse(payload);
          } catch (e) {
            console.log("[logentries] error parsing commit data, bailing. :(");
            console.log("[logentries] " + e.message);
            return false;
          }
          try {
            console.log("[logentries] parsed incoming");
            console.log(utils.inspect(incoming));
            new SpeakOnce(process.env.campfire_logging_room, function(room) {
              try {
                return room.speak("[logentries says] " + (util.inspect(incoming)) + "\"");
              } catch (ex) {
                return console.log("[logentries] error trying to post logentries incoming: " + ex.message);
              }
            });
            response.end('');
          } catch (ex) {
            console.log("[logentries] ERROR: " + ex.message);
            response.end(ex.message);
          }
          return true;
        });
        return true;
      }
    }
  };
}).call(this);
(function() {
  var logger, patterns, _;
  _ = require('underscore');
  logger = function(d) {
    try {
      return console.log("" + d.message.created_at + ": " + d.message.body);
    } catch (_e) {}
  };
  patterns = [];
  patterns.push({
    regex: /(^|[^a-zA-Z0-9])(\d{5})($|[^a-zA-Z0-9])/,
    template: process.env.helpspot_link_template
  });
  module.exports = {
    listen: function(msg, room, env) {
      if (/^!/.test(msg.body)) {
        return;
      }
      return _.each(patterns, function(pattern) {
        if (pattern.regex.test(msg.body)) {
          console.log("posting helpspot link: " + (msg.body.matching(pattern.regex)[2]));
          return room.speak(pattern.template.replace('$', msg.body.match(pattern.regex)[2]), logger);
        }
      });
    }
  };
}).call(this);

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
    regex: /\d{5}/,
    template: "http://figure53.com/support/admin.php?pg=request&reqid=$"
  });
  module.exports = {
    listen: function(msg, room, env) {
      if (/^!/.test(msg.body)) {
        return;
      }
      return _.each(patterns, function(pattern) {
        if (pattern.regex.test(msg.body)) {
          return room.speak(pattern.template.replace('$', msg.body.match(pattern.regex)[0]), logger);
        }
      });
    }
  };
}).call(this);

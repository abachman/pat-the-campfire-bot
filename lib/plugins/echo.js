(function() {
  var echo_matcher;
  echo_matcher = /^!echo\b(.*)/i;
  module.exports = {
    listen: function(message, room, logger) {
      var body;
      body = message.body;
      if (echo_matcher.test(body)) {
        console.log("echoing");
        return room.speak(echo_matcher.exec(body)[1], logger);
      }
    }
  };
}).call(this);

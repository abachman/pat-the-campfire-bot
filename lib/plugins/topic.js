(function() {
  module.exports = {
    name: "Topic",
    listen: function(message, room, logger) {
      var body, new_topic, phrase_matcher;
      body = message.body;
      phrase_matcher = /"([^\"]*)"/i;
      if (/pat/i.test(body) && /change/i.test(body) && /topic/i.test(body) && phrase_matcher.test(body)) {
        new_topic = phrase_matcher.exec(body)[1];
        console.log("updating topic from " + room.topic + " to " + new_topic);
        return room.update(new_topic, logger);
      }
    }
  };
}).call(this);
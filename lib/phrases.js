(function() {
  var api, phrases, _;
  _ = require('underscore')._;
  phrases = [
    {
      regex: /pat\?/,
      msg: "yeah, I'm here"
    }, {
      regex: /deal/,
      msg: ['DEAL WITH IT', "http://s3.amazonaws.com/gif.ly/gifs/490/original.gif?1294726461"]
    }, {
      regex: /noob/i,
      msg: 'http://www.marriedtothesea.com/022310/i-hate-thinking.gif'
    }, {
      regex: /imo/i,
      msg: ["http://s3.amazonaws.com/gif.ly/gifs/485/original.gif?1294425077", "well, that's just, like, your opinion, man."]
    }, {
      regex: /^(hi|hello|hey|yo )/i,
      msg: function(env) {
        if (env.speaker != null) {
          return "oh hai, " + env.speaker.name + "!";
        } else {
          return 'oh hai';
        }
      }
    }, {
      regex: /morning/i,
      msg: function(env) {
        if (env.speaker != null) {
          return "Good morning to you too, " + env.speaker.name + "!";
        } else {
          return 'good morning!';
        }
      }
    }, {
      regex: /afternoon/i,
      msg: "a pleasant good afternoon to you, as well"
    }, {
      regex: /night/i,
      msg: "it's probably not nighttime where I am"
    }
  ];
  api = {
    logger: function(d) {
      try {
        return console.log("" + d.message.created_at + ": " + d.message.body);
      } catch (_e) {}
    },
    phrases: phrases,
    listen: function(message, room, env) {
      return _.each(api.phrases, function(phrase) {
        if (!/pat/i.test(message.body)) {
          return;
        }
        if (!phrase.regex.test(message.body)) {
          return;
        }
        if (_.isArray(phrase.msg)) {
          _.each(phrase.msg, function(msg) {
            return room.speak(msg, api.logger);
          });
        } else if (_.isFunction(phrase.msg)) {
          room.speak(phrase.msg(env), api.logger);
        } else {
          room.speak(phrase.msg, api.logger);
        }
        if (_.isFunction(phrase.callback)) {
          return phrase.callback();
        }
      });
    }
  };
  module.exports = api;
}).call(this);

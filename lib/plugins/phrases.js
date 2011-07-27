(function() {
  var User, api, phrases, _;
  _ = require('underscore')._;
  User = require('../store').User;
  phrases = [
    {
      regex: /\bpat\?/i,
      msg: "yeah, I'm here"
    }, {
      regex: /deal with it/,
      msg: "http://s3.amazonaws.com/gif.ly/gifs/490/original.gif?1294726461"
    }, {
      regex: /\bnoob\b/i,
      msg: 'http://www.marriedtothesea.com/022310/i-hate-thinking.gif'
    }, {
      regex: /\bimo\b/i,
      msg: ["http://s3.amazonaws.com/gif.ly/gifs/485/original.gif?1294425077", "well, that's just, like, your opinion, man."]
    }, {
      regex: /^(hi|hello|hey|yo )/i,
      precedent: /\bpat\b/i,
      msg: _.template("<%= match %> yourself, <%= user.name %>")
    }, {
      regex: /morning/i,
      precedent: /\bpat\b/i,
      msg: _.template("Good morning to you too, <%= user.name %>!")
    }, {
      regex: /afternoon/i,
      precedent: /\bpat\b/i,
      msg: "a pleasant afternoon to you, as well"
    }, {
      regex: /night/i,
      precedent: /\bpat\b/i,
      msg: "it's probably not nighttime where i am"
    }
  ];
  phrases.push({
    regex: /do not want/i,
    msg: ["http://theducks.org/pictures/do-not-want-dog.jpg", "http://img69.imageshack.us/img69/3626/gatito13bj0.gif", "http://icanhascheezburger.files.wordpress.com/2007/03/captions03211.jpg?w=500&h=332", "http://icanhascheezburger.files.wordpress.com/2007/04/do-not-want.jpg?w=500&h=430", "http://wealsoran.com/music/uploaded_images/images_do_not_want-741689.jpg"],
    choice: true
  });
  api = {
    logger: function(d) {
      try {
        return console.log("" + d.message.created_at + ": " + d.message.body);
      } catch (_e) {}
    },
    phrases: phrases,
    listen: function(message, room) {
      return api.phrases.forEach(function(phrase) {
        var choose, match;
        if (phrase.precedent) {
          if (!phrase.precedent.test(message.body)) {
            return;
          }
        }
        if (!phrase.regex.test(message.body)) {
          return;
        }
        if (_.isArray(phrase.msg)) {
          if (phrase.choice) {
            choose = Math.floor(Math.random() * phrase.msg.length);
            room.speak(phrase.msg[choose], api.logger);
          } else {
            phrase.msg.forEach(function(msg) {
              return room.speak(msg, api.logger);
            });
          }
        } else if (_.isFunction(phrase.msg)) {
          match = message.body.match(phrase.regex)[1];
          User.findOne({
            user_id: message.user_id
          }, function(err, user) {
            if (user) {
              return room.speak(phrase.msg({
                match: match,
                user: user
              }), api.logger);
            } else {
              return room.speak(phrase.msg({
                match: match,
                user: {}
              }), api.logger);
            }
          });
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

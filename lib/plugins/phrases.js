(function() {
  var Phrase, Phrases, User, phrases, util, _, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ = require('underscore')._;
  util = require('util');
  _ref = require('../store'), User = _ref.User, Phrase = _ref.Phrase;
  phrases = [
    {
      regex: /\bpat\?/i,
      msg: "yeah, I'm here"
    }, {
      regex: /\bnoob\b/i,
      msg: 'http://www.marriedtothesea.com/022310/i-hate-thinking.gif'
    }, {
      regex: /morning/i,
      precedent: /\bpat\b/i,
      msg: _.template("Good morning to you too, <%= user.name %>!")
    }, {
      regex: /night/i,
      precedent: /\bpat\b/i,
      msg: "it's probably not nighttime where i am"
    }
  ];
  phrases.push({
    regex: /afternoon/i,
    precedent: /\bpat\b/i,
    msg: "a pleasant afternoon to you, as well"
  });
  phrases.push({
    precedent: /\bpat\b/i,
    regex: /^(hi|hello|hey|yo )/i,
    msg: _.template("<%= match %> yourself, <%= user.name %>")
  });
  phrases.push({
    regex: /deal with it/i,
    msg: "http://s3.amazonaws.com/gif.ly/gifs/490/original.gif?1294726461"
  });
  phrases.push({
    regex: /\bimo\b/i,
    msg: ["http://s3.amazonaws.com/gif.ly/gifs/485/original.gif?1294425077", "well, that's just, like, your opinion, man."]
  });
  phrases.push({
    regex: /do not want/i,
    msg: ["http://theducks.org/pictures/do-not-want-dog.jpg", "http://img69.imageshack.us/img69/3626/gatito13bj0.gif", "http://icanhascheezburger.files.wordpress.com/2007/03/captions03211.jpg?w=500&h=332", "http://icanhascheezburger.files.wordpress.com/2007/04/do-not-want.jpg?w=500&h=430", "http://wealsoran.com/music/uploaded_images/images_do_not_want-741689.jpg"],
    choice: true
  });
  Phrases = (function() {
    function Phrases(static_phrases) {
      var remove_matcher;
      this.static_phrases = static_phrases;
      this.load_phrases();
      this.re_matcher = /(\/[^/]+\/[a-z]{0,3})/i;
      this.phrase_matcher = /"([^\"]*)"/i;
      remove_matcher = this.re_matcher.toString();
      remove_matcher = remove_matcher.substr(1, remove_matcher.length - 3);
      this.remove_matcher = new RegExp("-" + remove_matcher);
    }
    Phrases.prototype.load_phrases = function() {
      this.phrases = [];
      this.static_phrases.forEach(__bind(function(phrase) {
        return this.phrases.push(phrase);
      }, this));
      return Phrase.find({}, __bind(function(err, stored_phrases) {
        stored_phrases.forEach(__bind(function(phrase) {
          console.log("Loading from mongo: " + (util.inspect(phrase)));
          if (phrase.pattern && phrase.pattern.length) {
            return this.phrases.push({
              regex: new RegExp(phrase.pattern, phrase.modifiers),
              msg: phrase.message
            });
          }
        }, this));
        return console.log("[Phrases] I know " + this.phrases.length + " phrases: " + (this.all_phrases()));
      }, this));
    };
    Phrases.prototype.logger = function(d) {
      try {
        return console.log("" + d.message.created_at + ": " + d.message.body);
      } catch (_e) {}
    };
    Phrases.prototype.all_phrases = function() {
      return _.map(this.phrases, function(phrase) {
        return phrase.regex.toString();
      }).join(', ');
    };
    Phrases.prototype.tell_all = function(room) {
      console.log("[Phrases] I know " + this.phrases.length + " phrases: " + (this.all_phrases()));
      return room.speak("I know " + this.phrases.length + " phrases: " + (this.all_phrases()), this.logger);
    };
    Phrases.prototype.get_isolated_pattern = function(pattern) {
      var mods, _leading, _trailing;
      _leading = /^\//;
      _trailing = /\/([a-z]{0,3})$/;
      mods = "";
      if (_trailing.test(pattern)) {
        mods = _trailing.exec(pattern)[1];
      }
      return {
        pattern: pattern.replace(_leading, '').replace(_trailing, ''),
        modifiers: mods
      };
    };
    Phrases.prototype.add_phrase = function(regex, phrase, message, room) {
      var modifiers, pattern, _ref2;
      _ref2 = this.get_isolated_pattern(regex), pattern = _ref2.pattern, modifiers = _ref2.modifiers;
      console.log("I got: {phrase: \"" + phrase + "\", pattern: \"" + pattern + "\", modifiers: \"" + modifiers + "\"}");
      return Phrase.findOne({
        pattern: pattern,
        modifiers: modifiers
      }, __bind(function(err, existing_phrase) {
        var _phrase;
        if (existing_phrase !== null) {
          room.speak("I already respond to /" + pattern + "/" + modifiers + ", sorry :(", this.logger);
          return;
        }
        _phrase = new Phrase({
          pattern: pattern,
          modifiers: modifiers,
          user_id: message.user_id,
          message: phrase
        });
        return _phrase.save(__bind(function(err, new_phrase) {
          return User.findOne({
            user_id: message.user_id
          }, __bind(function(err, user) {
            if (err) {
              room.speak("From now on, if anyone says " + pattern + ", I'll say \"" + new_phrase.message + "\"", this.logger);
            } else {
              room.speak("Thanks, " + (user.name.split(' ')[0]) + ", from now on if someone says " + pattern + ", I'll say \"" + new_phrase.message + "\"", this.logger);
            }
            return this.load_phrases();
          }, this));
        }, this));
      }, this));
    };
    Phrases.prototype.remove_phrase = function(regex, room) {
      var modifiers, pattern, _ref2;
      _ref2 = this.get_isolated_pattern(regex), pattern = _ref2.pattern, modifiers = _ref2.modifiers;
      return Phrase.findOne({
        pattern: pattern,
        modifiers: modifiers
      }, __bind(function(err, phrase) {
        if (err || phrase === null) {
          return room.speak("I couldn't find a phrase matching /" + pattern + "/" + modifiers);
        } else {
          return phrase.remove(__bind(function(err, p) {
            room.speak("I've removed a phrase matching /" + pattern + "/" + modifiers);
            return this.load_phrases();
          }, this));
        }
      }, this));
    };
    Phrases.prototype.match_phrase = function(message, room) {
      if (/pat/i.test(message.body) && /what.*know\??$/i.test(message.body)) {
        this.tell_all(room);
        return;
      }
      return this.phrases.forEach(__bind(function(phrase) {
        var choose, match;
        if (phrase.precedent) {
          if (!phrase.precedent.test(message.body)) {
            return;
          }
        }
        if (!phrase.regex.test(message.body)) {
          return;
        }
        console.log("matched " + message.body + " with " + (phrase.regex.toString()));
        if (_.isArray(phrase.msg)) {
          if (phrase.choice) {
            choose = Math.floor(Math.random() * phrase.msg.length);
            room.speak(phrase.msg[choose], this.logger);
          } else {
            phrase.msg.forEach(__bind(function(msg) {
              return room.speak(msg, this.logger);
            }, this));
          }
        } else if (_.isFunction(phrase.msg)) {
          match = message.body.match(phrase.regex)[1];
          User.findOne({
            user_id: message.user_id
          }, __bind(function(err, user) {
            if (user) {
              return room.speak(phrase.msg({
                match: match,
                user: user
              }), this.logger);
            } else {
              return room.speak(phrase.msg({
                match: match,
                user: {}
              }), this.logger);
            }
          }, this));
        } else {
          console.log("speaking the bare phrase: " + phrase.msg);
          room.speak(phrase.msg, this.logger);
        }
        if (_.isFunction(phrase.callback)) {
          return phrase.callback();
        }
      }, this));
    };
    Phrases.prototype.listen = function(message, room) {
      var body;
      body = message.body;
      if (/\bpat\b/i.test(body)) {
        if (this.re_matcher.test(body) && this.phrase_matcher.test(body)) {
          console.log("add a phrase");
          this.add_phrase(this.re_matcher.exec(body)[1], this.phrase_matcher.exec(body)[1], message, room);
          return;
        } else if (this.remove_matcher.test(body)) {
          console.log("remove a phrase");
          this.remove_phrase(this.re_matcher.exec(body)[1], room);
          return;
        }
      }
      return this.match_phrase(message, room);
    };
    return Phrases;
  })();
  module.exports = new Phrases(phrases);
}).call(this);

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
    regex: /^(hi|hello|hey|yo)[, ]/i,
    msg: _.template("<%= match %> yourself, <%= user.name %>")
  });
  phrases.push({
    regex: /deal with it/i,
    msg: "http://s3.amazonaws.com/gif.ly/gifs/490/original.gif"
  });
  phrases.push({
    regex: /\bimo\b/i,
    msg: ["http://s3.amazonaws.com/gif.ly/gifs/485/original.gif", "well, that's just, like, your opinion, man."]
  });
  phrases.push({
    regex: /do not want/i,
    msg: ["http://theducks.org/pictures/do-not-want-dog.jpg", "http://img69.imageshack.us/img69/3626/gatito13bj0.gif", "http://icanhascheezburger.files.wordpress.com/2007/03/captions03211.jpg", "http://icanhascheezburger.files.wordpress.com/2007/04/do-not-want.jpg", "http://wealsoran.com/music/uploaded_images/images_do_not_want-741689.jpg"],
    choice: true
  });
  Phrases = (function() {
    Phrases.prototype.name = "Phrases";
    function Phrases(static_phrases) {
      var remove_matcher;
      this.static_phrases = static_phrases;
      this.load_phrases();
      this.re_matcher = /(\/[^/]+\/[a-z]{0,3})/i;
      this.phrase_matcher = /"([^\"]*)"/i;
      remove_matcher = this.re_matcher.toString();
      remove_matcher = remove_matcher.substr(1, remove_matcher.length - 3);
      this.remove_matcher = new RegExp("-\\s*" + remove_matcher + "|forget\\s+" + remove_matcher);
    }
    Phrases.prototype.load_phrases = function() {
      this.phrases = [];
      this.static_phrases.forEach(__bind(function(phrase) {
        return this.phrases.push(phrase);
      }, this));
      return Phrase.find({}, __bind(function(err, stored_phrases) {
        stored_phrases.forEach(__bind(function(phrase) {
          var phr;
          if (phrase.pattern && phrase.pattern.length) {
            phr = {};
            try {
              phr.regex = new RegExp(phrase.pattern, phrase.modifiers);
            } catch (e) {
              console.log("Couldn't load invalid regex /" + phrase.pattern + "/" + phrase.modifiers + "! " + e.message);
              return;
            }
            if (phrase.choice) {
              phr.choice = true;
              phr.msg = JSON.parse(phrase.message);
            } else {
              phr.msg = phrase.message;
            }
            return this.load_phrase_into_cache(phr);
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
    Phrases.prototype.load_phrase_into_cache = function(phr) {
      var _existing;
      if (!phr.regex) {
        phr.regex = new RegExp(phr.pattern, phr.modifiers);
      }
      if (!phr.msg) {
        if (phr.choice) {
          phr.msg = JSON.parse(phr.message);
        } else {
          phr.msg = phr.message;
        }
      }
      _existing = _.find(this.phrases, function(p) {
        return p.regex.toString() === phr.regex.toString();
      });
      if (_existing != null) {
        console.log("" + phr.regex + " is not unique, adding to existing matcher");
        if (_existing.choice || typeof _existing.msg === 'Array') {
          if (typeof _existing.msg !== "Array") {
            _existing.msg = JSON.parse(_existing.msg);
          }
          console.log("Existing message is an Array");
          if (phr.choice || typeof phr.msg === 'Array') {
            if (typeof phr.msg !== "Array") {
              phr.msg = JSON.parse(phr.msg);
            }
            console.log("Loaded message is an Array");
            _.each(phr.msg, function(m) {
              return _existing.msg.push(m);
            });
          } else {
            console.log("Loaded message is a String: " + phr.msg);
            _existing.msg.push(phr.msg);
          }
        } else {
          console.log("Existing message is a String");
          if (phr.choice || typeof phr.msg === 'Array') {
            console.log("Loaded message is an Array");
            phr.msg.push(_existing.msg);
            _existing.msg = phr.msg;
          } else {
            console.log("Loaded message is a String: " + phr.msg);
            _existing.msg = [_existing.msg, phr.msg];
          }
        }
        _existing.choice = true;
        return console.log("Updated existing message: " + (util.inspect(_existing.msg)));
      } else {
        return this.phrases.push(phr);
      }
    };
    Phrases.prototype.remove_phrase_from_cache = function(phr) {
      var _after, _before;
      _before = this.phrases.length;
      this.phrases = _.reject(this.phrases, function(p) {
        return p.regex.toString() === phr.regex.toString();
      });
      _after = this.phrases.length;
      console.log("[remove_phrase_from_cache] removed " + (_before - _after) + " phrases from local cache");
      return _before - _after;
    };
    Phrases.prototype.all_phrases = function() {
      return _.map(this.phrases, function(phrase) {
        return phrase.regex.toString();
      }).join(', ');
    };
    Phrases.prototype.tell_all = function(room) {
      room.speak("I know " + this.phrases.length + " phrases: " + (this.all_phrases()) + ".", this.logger);
      return room.speak("Say `pat /pattern/ \"phrase\"` to help me remember and `pat forget /pattern/` or `pat -/pattern/` to let me forget.", this.logger);
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
    Phrases.prototype.save_phrase = function(phrase_record, message, room) {
      return phrase_record.save(__bind(function(err, new_phrase) {
        return User.findOne({
          user_id: message.user_id
        }, __bind(function(err, user) {
          var response;
          response = "";
          if (user) {
            response = "Thanks " + (user.name.split(' ')[0]) + "!  ";
          }
          response += "From now on, if anyone says " + new_phrase.pattern + ", ";
          if (new_phrase.choice) {
            phrases = JSON.parse(new_phrase.message);
            response += "I'll choose from " + phrases.length + " responses";
          } else {
            response += "I'll say \"" + new_phrase.message + "\"";
          }
          room.speak(response, this.logger);
          return this.load_phrase_into_cache(new_phrase);
        }, this));
      }, this));
    };
    Phrases.prototype.add_phrase = function(regex, phrase, message, room) {
      var modifiers, pattern, _ref2;
      _ref2 = this.get_isolated_pattern(regex), pattern = _ref2.pattern, modifiers = _ref2.modifiers;
      regex = null;
      try {
        regex = new RegExp(pattern, modifiers);
      } catch (e) {
        console.log("invalid regex detected: /" + pattern + "/" + modifiers + " : " + e.message);
        room.speak("That was a bad regex :(", this.logger);
        return;
      }
      console.log("I got: {phrase: \"" + phrase + "\", pattern: \"" + pattern + "\", modifiers: \"" + modifiers + "\"}");
      return Phrase.findOne({
        pattern: pattern,
        modifiers: modifiers
      }, __bind(function(err, existing_phrase) {
        var _phrase, _phrases;
        if (existing_phrase) {
          console.log("" + regex + " already exists in storage");
          if (existing_phrase.choice) {
            _phrases = JSON.parse(existing_phrase.message);
            _phrases.push(phrase);
            existing_phrase.message = JSON.stringify(_phrases);
          } else {
            existing_phrase.message = JSON.stringify([existing_phrase.message, phrase]);
            existing_phrase.choice = true;
          }
          this.save_phrase(existing_phrase, message, room);
          return;
        }
        _phrase = new Phrase({
          pattern: pattern,
          modifiers: modifiers,
          user_id: message.user_id,
          message: phrase
        });
        return this.save_phrase(_phrase, message, room);
      }, this));
    };
    Phrases.prototype.remove_phrase = function(regex, room) {
      var modifiers, pattern, _ref2, _removed;
      _ref2 = this.get_isolated_pattern(regex), pattern = _ref2.pattern, modifiers = _ref2.modifiers;
      _removed = this.remove_phrase_from_cache({
        regex: new RegExp(pattern, modifiers)
      });
      return Phrase.findOne({
        pattern: pattern,
        modifiers: modifiers
      }, __bind(function(err, phrase) {
        if (err || phrase === null) {
          if (_removed > 0) {
            return room.speak(("I couldn't find a phrase matching /" + pattern + "/" + modifiers + " in storage, ") + ("but removed " + _removed + " from my local cache. The pattern may have a hard lock in my source code, it itches."));
          } else {
            return room.speak("I couldn't find a phrase matching /" + pattern + "/" + modifiers + " in storage or in the local cache");
          }
        } else {
          return phrase.remove(__bind(function(err, p) {
            return room.speak("I've removed a phrase matching /" + pattern + "/" + modifiers + " from storage and " + _removed + " matching that from the local cache. I am sincerely sorry I ever learned it in the first place :(");
          }, this));
        }
      }, this));
    };
    Phrases.prototype.match_phrase = function(message, room) {
      if (/pat/i.test(message.body) && /what.*know\??$/i.test(message.body)) {
        this.tell_all(room);
        return true;
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
          return true;
        } else if (this.remove_matcher.test(body)) {
          console.log("remove a phrase");
          this.remove_phrase(this.re_matcher.exec(body)[1], room);
          return true;
        }
      }
      return this.match_phrase(message, room);
    };
    return Phrases;
  })();
  module.exports = new Phrases(phrases);
}).call(this);

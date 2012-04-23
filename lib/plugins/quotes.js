(function() {
  var curl, qs, quote_host, quote_port, source_report, util, valid_sources, _;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  util = require('util');
  curl = require('../vendor/simple_http').curl;
  qs = require('querystring');
  _ = require('underscore')._;
  quote_host = 'www.iheartquotes.com';
  quote_port = 80;
  valid_sources = ['esr', 'humorix_misc', 'humorix_stories', 'joel_on_software', 'macintosh', 'math', 'mav_flame', 'osp_rules', 'paul_graham', 'prog_style', 'subversion', '1811_dictionary_of_the_vulgar_tongue', 'codehappy', 'fortune', 'liberty', 'literature', 'misc', 'oneliners', 'riddles', 'rkba', 'shlomif', 'shlomif_fav', 'stephen_wright', 'calvin', 'forrestgump', 'friends', 'futurama', 'holygrail', 'powerpuff', 'simon_garfunkel', 'simpsons_cbg', 'simpsons_chalkboard', 'simpsons_homer', 'simpsons_ralph', 'south_park', 'starwars', 'xfiles', 'contentions', 'osho', 'cryptonomicon', 'discworld', 'dune', 'hitchhiker'];
  source_report = "From geek: esr humorix_misc humorix_stories joel_on_software macintosh math mav_flame osp_rules paul_graham prog_style subversion\nFrom general: 1811_dictionary_of_the_vulgar_tongue codehappy fortune liberty literature misc oneliners riddles rkba shlomif shlomif_fav stephen_wright\nFrom pop: calvin forrestgump friends futurama holygrail powerpuff simon_garfunkel simpsons_cbg simpsons_chalkboard simpsons_homer simpsons_ralph south_park starwars xfiles\nFrom scifi: cryptonomicon discworld dune hitchhiker\n\nhttp://iheartquotes.com/api";
  module.exports = {
    name: "Quotes",
    listen: function(message, room, logger) {
      var body, options, source, word;
      body = message.body;
      if (body == null) {
        return;
      }
      if (/^pat/i.test(body) && /quote/i.test(body)) {
        if (/sources/i.test(body)) {
          room.paste(source_report, logger);
          return;
        }
        source = _.find((function() {
          var _i, _len, _ref, _results;
          _ref = body.split(' ');
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            word = _ref[_i];
            _results.push(word);
          }
          return _results;
        })(), function(w) {
          return __indexOf.call(valid_sources, w) >= 0;
        });
        if (source == null) {
          source = valid_sources[Math.floor(Math.random() * valid_sources.length)];
        }
        options = {
          host: quote_host,
          port: quote_port,
          path: "/api/v1/random?format=json&source=" + source
        };
        return curl(options, function(data) {
          var results;
          console.log("results for " + source + " are ready! " + data);
          results = JSON.parse(data);
          if ((results != null) && (results.quote != null)) {
            return room.speak(results.quote, logger);
          } else {
            return room.speak("whoops, looks like they don't have any quotes for that", logger);
          }
        });
      }
    }
  };
}).call(this);
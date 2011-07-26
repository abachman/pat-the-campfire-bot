(function() {
  var Counter, User, campfire_stats, date_id, store, _;
  _ = require('underscore')._;
  store = require('../store');
  Counter = store.Counter;
  User = store.User;
  date_id = store.date_id;
  campfire_stats = function(message, room) {
    var results, tdate, today;
    today = date_id();
    tdate = new Date;
    console.log('preparing campfire stats for today');
    message = "Campfire tally for " + (tdate.getFullYear()) + "-" + (tdate.getMonth() + 1) + "-" + (tdate.getDate()) + ". ";
    results = {};
    return Counter.findOne({
      name: today
    }, function(e, counter) {
      console.log("found today counter");
      if (counter) {
        results.Total = counter.value;
      } else {
        results.Total = 0;
        return;
      }
      return User.find({}, [], function(err, users) {
        var ticks;
        ticks = users.length;
        return users.forEach(function(user) {
          var uid;
          uid = "" + user.user_id + "-" + today;
          return Counter.findOne({
            name: uid
          }, function(e, counter) {
            var counters, list;
            if (counter) {
              results[user.name] = counter.value;
            } else {
              results[user.name] = 0;
            }
            ticks--;
            if (ticks === 0) {
              counters = _.keys(results);
              counters = _.sortBy(counters, function(c) {
                return results[c];
              });
              list = _.map(counters, function(c) {
                return "" + c + ": " + results[c];
              });
              message += list.join(', ');
              return room.speak(message);
            }
          });
        });
      });
    });
  };
  module.exports = {
    listen: function(message, room) {
      if (/pat/i.test(message.body) && /stats/i.test(message.body)) {
        console.log('stats request?');
        if (/(campfire|cf)/i.test(message.body)) {
          return campfire_stats(message, room);
        }
      }
    }
  };
}).call(this);
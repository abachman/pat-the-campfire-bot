(function() {
  var Campfire, Counter, EventEmitter, NODE_ENV, User, bot, debuglog, find_or_create_user, heartbeat, http, increment, instance, logger, plugins, port, server, store, track_message, util, _;
  http = require('http');
  Campfire = require('./vendor/campfire').Campfire;
  _ = require('underscore')._;
  EventEmitter = require('events').EventEmitter;
  util = require('util');
  store = require('./store');
  User = store.User;
  Counter = store.Counter;
  plugins = require('./plugins/');
  NODE_ENV = process.env.node_env || 'development';
  logger = function(d) {
    return console.log("" + d.message.created_at + ": " + d.message.body);
  };
  debuglog = function(message) {
    if (NODE_ENV !== 'production' || process.env.DEBUG) {
      return console.log(message);
    }
  };
  bot = {};
  instance = new Campfire({
    ssl: true,
    token: process.env.campfire_bot_token,
    account: process.env.campfire_bot_account
  });
  instance.me(function(msg) {
    return bot = msg.user;
  });
  find_or_create_user = function(user_id, channel) {
    return User.findOne({
      user_id: user_id
    }, function(err, result) {
      if (result != null) {
        debuglog('user recognized');
        return channel.emit('ready');
      } else {
        debuglog('user unrecognized');
        console.info("looking up user_id " + user_id);
        return instance.user(user_id, function(response) {
          var user;
          user = response.user;
          debuglog("from campfire, I got " + (util.inspect(user)));
          debuglog("campfire: " + arguments);
          user = new User({
            user_id: user.id,
            name: user.name,
            email: user.email_address,
            avatar_url: user.avatar_url,
            created_at: user.created_at
          });
          return user.save(function(err, record) {
            if (err) {
              console.error("ERROR: " + err.message);
              throw err;
            } else {
              debuglog("tagged user, " + record.user_id + "!");
              return channel.emit('ready');
            }
          });
        });
      }
    });
  };
  increment = function(name) {
    return Counter.findOne({
      name: name
    }, function(err, counter) {
      if (counter != null) {
        counter.value = counter.value + 1;
        return counter.save(function() {});
      } else {
        counter = new Counter({
          name: name,
          value: 1
        });
        return counter.save(function() {});
      }
    });
  };
  track_message = function(msg) {
    var date, date_id, user_date_id;
    date = new Date;
    date_id = "messages-" + (date.getFullYear()) + "-" + (date.getMonth()) + "-" + (date.getDate());
    increment(date_id);
    user_date_id = "" + msg.user_id + "-" + date_id;
    return increment(user_date_id);
  };
  heartbeat = null;
  instance.room(process.env.campfire_bot_room, function(room) {
    var handle_message;
    handle_message = function(message) {};
    room.join(function() {
      var ping_room, room_event_loop;
      console.info("bot with id " + bot.id + " is joining " + room.name);
      User.find({}, function(err, users) {
        if (users.length) {
          return console.info("I know: " + (_.map(users, function(u) {
            return u.name;
          }).join(', ')));
        } else {
          return debuglog("I don't know anyone yet.");
        }
      });
      if (!process.env.SILENT) {
        room.speak("hai guys, it's me, " + bot.name + "!", logger);
      }
      room_event_loop = function() {
        return room.listen(function(msg) {
          var channel;
          if (msg.user_id === null || msg.user_id === parseInt(bot.id)) {
            return;
          }
          track_message(msg);
          debuglog("-----------------\nMESSAGE RECEIVED!");
          channel = new EventEmitter();
          find_or_create_user(msg.user_id, channel);
          return channel.on('ready', function() {
            return plugins.notify(msg, room);
          });
        });
      };
      console.log("Joining " + room.name);
      room_event_loop();
      room.events.on('listen:disconnect', function() {
        console.log("lost connection to Campfire, reattaching");
        return room_event_loop();
      });
      if (heartbeat) {
        debuglog("clearing heartbeat timeout");
        clearTimeout(heartbeat);
      }
      ping_room = function() {
        room.ping(function() {
          return console.log('heartbeat');
        });
        return setTimeout(ping_room, 60000 * 8);
      };
      return heartbeat = ping_room();
    });
    return process.on('SIGINT', function() {
      return room.leave(function() {
        console.log('\nGood Luck, Star Fox');
        return process.exit();
      });
    });
  });
  server = http.createServer(function(req, res) {
    console.log("recieved request: " + (util.inspect(req)));
    if (!plugins.http_notify(req, res)) {
      res.writeHead(200, {
        'Content-Type': 'text/html'
      });
      return res.end("    <pre>" + (bot.name || 'bot') + " &lt;3s you</pre>    ");
    }
  });
  port = process.env.PORT || 5000;
  server.listen(port, function() {
    return console.log("listening on port " + port);
  });
}).call(this);

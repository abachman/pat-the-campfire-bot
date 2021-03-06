// Generated by CoffeeScript 1.8.0
(function() {
  var Campfire, Hipchat, HipchatRoom, SpeakOnce, _,
    __slice = [].slice;

  Campfire = require('../vendor/campfire').Campfire;

  Hipchat = require('../vendor/hipchat');

  _ = require('underscore')._;

  HipchatRoom = (function() {
    function HipchatRoom(attrs) {
      this.hipchat = new Hipchat(attrs.api_key);
      delete attrs.api_key;
      this.attrs = attrs;
    }

    HipchatRoom.prototype.speak = function(msg, log) {
      _.extend(this.attrs, {
        message: msg
      });
      console.log("[HipchatRoom speak] sending", this.attrs);
      return this.hipchat.postMessage(this.attrs, function(data, error_buffer) {
        if (data == null) {
          return console.log("[HipchatRoom speak] problems: ", error_buffer);
        } else {
          return console.log("[HipchatRoom speak] message has been sent!", data);
        }
      });
    };

    return HipchatRoom;

  })();

  SpeakOnce = (function() {
    function SpeakOnce() {
      var args, callback, hipchat, room_id;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (_.isFunction(args[0])) {
        room_id = process.env.campfire_service_room;
        callback = args[0];
      } else {
        room_id = args[0];
        callback = args[1];
      }
      this.campfire = new Campfire({
        ssl: true,
        token: process.env.campfire_bot_token,
        account: process.env.campfire_bot_account
      });
      this.campfire.room(room_id, function(room) {
        return callback(room);
      });
      if ((process.env.hipchat_api_key != null) && (process.env.hipchat_bot_room != null)) {
        hipchat = new HipchatRoom({
          api_key: process.env.hipchat_api_key,
          room_id: process.env.hipchat_bot_room,
          from: 'Pat B.'
        });
        callback(hipchat);
      }
    }

    return SpeakOnce;

  })();

  module.exports = {
    SpeakOnce: SpeakOnce
  };

}).call(this);

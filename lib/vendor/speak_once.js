(function() {
  var Campfire, SpeakOnce;
  Campfire = require('../vendor/campfire').Campfire;
  SpeakOnce = (function() {
    function SpeakOnce(callback) {
      this.campfire = new Campfire({
        ssl: true,
        token: process.env.campfire_bot_token,
        account: process.env.campfire_bot_account
      });
      this.campfire.room(process.env.campfire_bot_room, function(room) {
        return callback(room);
      });
    }
    return SpeakOnce;
  })();
  module.exports = {
    SpeakOnce: SpeakOnce
  };
}).call(this);

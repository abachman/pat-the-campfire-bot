(function() {
  var Counter, CounterSchema, EventEmitter, Phrase, PhraseSchema, Schema, User, UserSchema, db, events, mongo_url, mongoose, util;
  util = require('util');
  EventEmitter = require('events').EventEmitter;
  mongoose = require('mongoose');
  mongo_url = process.env.MONGOLAB_URI || 'mongodb://localhost/campfire-bot';
  db = mongoose.connect(mongo_url);
  Schema = mongoose.Schema;
  UserSchema = new Schema({
    type: String,
    created_at: String,
    user_id: {
      type: String,
      unique: true
    },
    name: String,
    email: String,
    avatar_url: String
  });
  User = mongoose.model("User", UserSchema);
  PhraseSchema = new Schema({
    user_id: String,
    message: String,
    pattern: String,
    modifiers: String,
    choice: {
      type: Boolean,
      "default": false
    },
    created_at: {
      type: Date,
      "default": function() {
        return new Date;
      }
    }
  });
  Phrase = mongoose.model("Phrase", PhraseSchema);
  CounterSchema = new Schema({
    name: {
      type: String,
      unique: true
    },
    value: Number,
    last_updated_at: Date
  });
  Counter = mongoose.model('Counter', CounterSchema);
  events = new EventEmitter();
  module.exports = {
    User: User,
    Phrase: Phrase,
    Counter: Counter,
    events: events,
    date_id: function(prefix) {
      var d_id, date;
      date = new Date;
      d_id = "messages-" + (date.getFullYear()) + "-" + (date.getMonth()) + "-" + (date.getDate());
      if (prefix) {
        d_id = "" + prefix + "-" + d_id;
      }
      return d_id;
    }
  };
}).call(this);

util           = require 'util'
{EventEmitter} = require 'events'
mongoose       = require 'mongoose'
            # production DB         || development DB
mongo_url = process.env.MONGOLAB_URI || 'mongodb://localhost/campfire-bot'
db = mongoose.connect( mongo_url )

Schema   = mongoose.Schema

UserSchema = new Schema
  type: String
  created_at: String
  user_id: 
    type: String
    unique: true
  name: String
  email: String
  avatar_url: String
User = mongoose.model "User", UserSchema

QuoteSchema = new Schema
  user_id: String
  text: String
  created_at:
    type: Date
    default: () -> new Date
Quote = mongoose.model "Quote", QuoteSchema

CounterSchema = new Schema
  name:
    type: String
    unique: true
  value: Number
  last_updated_at: Date
Counter = mongoose.model 'Counter', CounterSchema

events = new EventEmitter()

module.exports =
  User: User
  Quote: Quote
  Counter: Counter

  # communication
  events: events

  # utilities
  date_id: (prefix) ->
    date = new Date
    d_id = "messages-#{ date.getFullYear() }-#{ date.getMonth() }-#{ date.getDate() }"
    d_id = "#{ prefix }-#{ d_id }" if prefix

    d_id

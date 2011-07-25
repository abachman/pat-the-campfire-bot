# Module Requirements
http       = require 'http'
{Campfire} = require './vendor/campfire' 
{_}        = require 'underscore'
{EventEmitter} = require 'events'
util = require 'util'

# models
store   = require './store'
User    = store.User
Counter = store.Counter

# plugins
plugins = require './plugins/'

NODE_ENV = process.env.node_env || 'development'

# utility methods
logger = ( d ) ->
  console.log "#{d.message.created_at}: #{d.message.body}"

debuglog = (message) ->
  if NODE_ENV != 'production' or process.env.DEBUG
    console.log(message)

bot = {}

# Campfire instance
instance  = new Campfire
  ssl: true
  token: process.env.campfire_bot_token
  account: process.env.campfire_bot_account

instance.me (msg) -> 
  bot = msg.user

find_or_create_user = (user_id, channel) -> 
  User.findOne {user_id: user_id}, (err, result) ->
    if result?
      debuglog 'user recognized'
      channel.emit 'ready'
    else
      debuglog 'user unrecognized'
      console.info "looking up user_id #{ user_id }" 

      # get user from campfire API
      instance.user user_id, (response) ->
        user = response.user

        debuglog "from campfire, I got #{ util.inspect(user) }"
        debuglog "campfire: #{ arguments }"

        user = new User
          user_id:    user.id
          name:       user.name
          email:      user.email_address
          avatar_url: user.avatar_url
          created_at: user.created_at

        user.save (err, record) -> 
          if err
            console.error "ERROR: #{ err.message }"
            throw err
          else
            debuglog "tagged user, #{ record.user_id }!"
            channel.emit 'ready'

increment = (name) ->
  Counter.findOne {name: name}, (err, counter) ->
    if counter?
      counter.value = counter.value + 1
      counter.save () -> # console.log "counted #{ name }" 
    else
      counter = new Counter
        name: name
        value: 1
      counter.save () -> # console.log "counted #{ name }"

track_message = (msg) ->
  date = new Date

  # for today
  date_id = "messages-#{ date.getFullYear() }-#{ date.getMonth() }-#{ date.getDate() }"
  increment date_id

  # for user today
  user_date_id = "#{ msg.user_id }-#{ date_id }"
  increment user_date_id

# enter the main room
instance.room process.env.campfire_bot_room, ( room ) ->

  # the message emitter
  handle_message = (message) ->

  # join the main conversation room
  room.join ->
    console.info "bot with id #{ bot.id } is joining #{room.name}"

    # who do I know?
    User.find {}, (err, users) -> 
      if users.length
        console.info "I know: #{ _.map(users, (u) -> u.name).join(', ') }" 
      else
        debuglog "I don't know anyone yet."

    room.speak("hai guys, it's me, #{bot.name}!", logger) unless process.env.SILENT

    room.listen ( msg ) ->
      # ignore it if it's a system message or I said it 
      return if msg.user_id is null or msg.user_id == parseInt(bot.id)

      # stats
      track_message msg

      debuglog "MESSAGE RECEIVED!"

      # after receving each message, load the relevant user before processing the message
      channel = new EventEmitter()

      # f_o_c_u emits 'ready' signal on channel
      find_or_create_user msg.user_id, channel

      # forward message to plugins
      channel.on 'ready', () ->
        plugins.notify msg, room
        
     console.log "Joining #{room.name}"

  # leave the room on exit
  process.on 'SIGINT', ->
    room.leave ->
      console.log '\nGood Luck, Star Fox'
      process.exit()

# heroku wants the app to bind to a port, so lets do that
server = http.createServer ( req, res ) ->
  res.writeHead 200, { 'Content-Type': 'text/plain' }
  res.end "#{ bot.name || 'bot' } <3s you\n"

port = process.env.PORT || 3000

server.listen port, () -> console.log("listening on port #{ port }")

# Module Requirements
http           = require 'http'
{Campfire}     = require './vendor/campfire'
{_}            = require 'underscore'
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
campfire_instance  = new Campfire
  ssl: true
  token: process.env.campfire_bot_token
  account: process.env.campfire_bot_account

campfire_instance.me (msg) ->
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
      campfire_instance.user user_id, (response) ->
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
            # throw err
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

# global heartbeat timeout id
heartbeats   = {}
joined_rooms = []

shut_it_down = ->
  room.leave() for room in joined_rooms
  setTimeout((->
    process.exit()
  ), 1000)

room_joiner = (room) ->
  # join the main conversation room
  room.join ->
    joined_rooms.push(room) unless joined_rooms.indexOf(room) >= 0

    console.info "bot with id #{ bot.id } is joining #{room.name}"

    # who do I know?
    User.find {}, (err, users) ->
      if users.length
        console.info "I know: #{ _.map(users, (u) -> u.name).join(', ') }"
      else
        debuglog "I don't know anyone yet."

    room.speak("hai guys, it's me, #{bot.name}!", logger) unless process.env.SILENT

    room_event_loop = ->
      room.listen ( msg ) ->
        # ignore it if it's a system message or I said it
        return if msg.user_id is null or msg.user_id == parseInt(bot.id)

        # stats
        track_message msg

        debuglog "-----------------\nMESSAGE RECEIVED!"

        # after receving each message, load the relevant user before processing the message
        channel = new EventEmitter()

        # f_o_c_u emits 'ready' signal on channel
        find_or_create_user msg.user_id, channel

        # forward message to plugins
        channel.on 'ready', () ->
          plugins.notify msg, room

    console.log "Joining #{room.name}"
    room_event_loop()

    room.events.on 'listen:disconnect', () ->
      # start listening again
      console.log "lost connection to Campfire, killing process"
      shut_it_down()

    # clear before setting in case room.join is being called again

    if heartbeats[room.id]?
      debuglog "clearing heartbeat timeout for #{ room.id }"
      clearTimeout heartbeats[room.id]

    # ping to prevent connection loss
    ping_room = () ->
      room.ping ->
        console.log("heartbeat for #{ room.id }")
      # every 8 minutes
      setTimeout ping_room, (60000 * 8)
    heartbeats[room.id] = ping_room()

# enter the main room
room_list = process.env.campfire_bot_room.split(',')

for bot_room in room_list
  console.log "attempting to join room #{ bot_room }"
  campfire_instance.room(bot_room, (room) ->
    if room?
      console.log "joining room", room.id, room.name
      room_joiner(room)
  )

# leave the room on exit
process.on 'SIGINT', ->
  shut_it_down()

process.on 'uncaughtException', (err) ->
  console.error(err.stack)
  shut_it_down()

# heroku wants the app to bind to a port, so let's do that. We also might as
# well listen to http requests.
server = http.createServer (req, res) ->
  console.log "received request #{ req.url }, #{ req.method }"

  unless plugins.http_notify(req, res)
    res.writeHead 200, { 'Content-Type': 'text/html' }
    res.end "<pre>bot &lt;3s you</pre>"

port = process.env.PORT || 5000

server.listen port, ->
  console.log("listening on port #{ port }")

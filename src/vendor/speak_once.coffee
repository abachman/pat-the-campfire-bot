# provide simple access
{Campfire} = require '../vendor/campfire'
{_} = require 'underscore'

class SpeakOnce
  constructor: (args...) ->
    if _.isFunction(args[0])
      room_id = process.env.campfire_service_room
      callback = args[0]
    else
      room_id = args[0]
      callback = args[1]

    @campfire  = new Campfire
      ssl: true
      token: process.env.campfire_bot_token
      account: process.env.campfire_bot_account

    @campfire.room room_id, (room) ->
      callback(room)

module.exports =
  SpeakOnce: SpeakOnce

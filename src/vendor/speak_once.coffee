# provide simple access
{Campfire} = require '../vendor/campfire'
Hipchat = require '../vendor/hipchat'
{_} = require 'underscore'

class HipchatRoom
  constructor: (attrs) ->
    @hipchat = new Hipchat(attrs.api_key)
    delete attrs.api_key
    @attrs = attrs

  speak: (msg, log) ->
    _.extend(@attrs, {message: msg})

    console.log "[HipchatRoom speak] sending", @attrs

    @hipchat.postMessage @attrs, (data, error_buffer) ->
      if !data?
        console.log "[HipchatRoom speak] problems: ", error_buffer
      else
        console.log "[HipchatRoom speak] message has been sent!", data

class SpeakOnce
  constructor: (args...) ->
    if _.isFunction(args[0])
      room_id = process.env.campfire_service_room
      callback = args[0]
    else
      room_id = args[0]
      callback = args[1]

    @campfire = new Campfire
      ssl: true
      token: process.env.campfire_bot_token
      account: process.env.campfire_bot_account

    @campfire.room room_id, (room) ->
      callback(room)

    if process.env.hipchat_api_key? && process.env.hipchat_bot_room?
      hipchat = new HipchatRoom(
        api_key: process.env.hipchat_api_key
        room_id: process.env.hipchat_bot_room
        from: 'Pat B.'
      )
      callback(hipchat)

module.exports =
  SpeakOnce: SpeakOnce

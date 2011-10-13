# provide simple access
{Campfire} = require '../vendor/campfire'

class SpeakOnce
  constructor: (callback) ->
    @campfire  = new Campfire
      ssl: true
      token: process.env.campfire_bot_token
      account: process.env.campfire_bot_account

    @campfire.room process.env.campfire_bot_room, (room) ->
      callback(room)

module.exports =
  SpeakOnce: SpeakOnce

util      = require('util')
SpeakOnce = require('../vendor/speak_once').SpeakOnce
qs        = require('querystring')

echo_matcher = /^!echo\b(.*)/i
spoken_messages = {}

module.exports =
  name: "echo"
  http_listen: (request, response, logger) ->
    if /\/say/i.test request.url
      if /post/i.test request.method

        # POST
        # get all data
        data = ""

        request.on 'data', (incoming) ->
         data += incoming

        request.on 'end', ->
          console.log "[echo] recieved POST #{ data }"
          full_data = qs.parse(data)
          message = full_data.message
          room_number = if full_data.room? then full_data.room else null
          console.log "[echo] recieved data (#{typeof full_data}): #{ util.inspect(full_data) }"
          console.log "[echo] recieved message (#{typeof message}): #{ message }"

          # output
          response.writeHead 200, {'Content-Type': 'text/plain'}

          date = new Date

          # only allow reposting after 30 seconds
          if spoken_messages[message] and date - spoken_messages[message] < 30000
            # blocked!
            console.log "[echo] attempted to repost message before time expired: BLOCKED"
          else
            speak_callback = (room) -> room.speak(message, logger)
            if room_number?
              new SpeakOnce(room_number, speak_callback)
            else
              new SpeakOnce(speak_callback)
            spoken_messages[message] = date

          response.end ''

  listen: (message, room, logger) ->
    body = message.body

    if echo_matcher.test(body)
      console.log "echoing"
      room.speak echo_matcher.exec(body)[1], logger

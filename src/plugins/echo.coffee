SpeakOnce = require('../vendor/speak_once').SpeakOnce
qs        = require('querystring')

echo_matcher = /^!echo\b(.*)/i

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
          message = qs.parse(data).message
          console.log "[echo] recieved data (#{typeof message}): #{ message }"

          # output
          response.writeHead 200, {'Content-Type': 'text/plain'}

          new SpeakOnce (room) -> room.speak(message)

          response.end ''

  listen: (message, room, logger) ->
    body = message.body

    if echo_matcher.test(body)
      console.log "echoing"
      room.speak echo_matcher.exec(body)[1], logger

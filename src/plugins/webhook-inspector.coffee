util       = require('util')
{curl, getClientIp} = require('../vendor/simple_http')
SpeakOnce  = require('../vendor/speak_once').SpeakOnce
{_}        = require('underscore')
qs         = require('querystring')

IS_LISTENING = false

module.exports =
  name: "Webhook Inspector"

  http_listen: (request, response, logger) ->
    if /\/webhook-inspector/i.test request.url
      clientIp = getClientIp request

      console.log "/webhook-inspector got a #{request.method} message from #{ clientIp }"

      response.writeHead 200, {'Content-Type': 'text/html'}
      response.end if IS_LISTENING then "okay #{ clientIp }" else "la la la, I'm not listening"

      return unless IS_LISTENING

      data = ""

      request.on 'data', (incoming) ->
        data += incoming

      request.on 'end', ->
        new SpeakOnce (room) ->
          if data.length > 0
            room.speak "I received a #{ request.method } request on #{request.headers.host}#{request.url} from #{ clientIp }, it is #{ data.length } bytes.", logger
            room.paste data, logger

      # # empty response
      # response.writeHead 200, {'Content-Type': 'text/plain'}
      # response.end ''

  listen: (message, room, logger) ->
    body = message.body

    mah_name = /pat/i
    matcher = /(start|stop) inspecting webhooks/i

    if mah_name.test(body) and matcher.test(body)
      state = matcher.exec(body)[1]

      if /start/i.test state
        room.speak "I'm inspecting webhooks #{ if IS_LISTENING then 'already' else 'now' }."
        IS_LISTENING = true
      else
        room.speak "I've stopped inspecting webhooks #{ if !IS_LISTENING then 'already' else 'now' }."
        IS_LISTENING = false


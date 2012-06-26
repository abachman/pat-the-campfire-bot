util       = require('util')
curl       = require('../vendor/simple_http').curl
SpeakOnce  = require('../vendor/speak_once').SpeakOnce
{_}        = require('underscore')
qs         = require('querystring')

getClientIp = (request) ->
  # the request may be forwarded from local web server.
  forwardedIpsStr = request.headers['x-forwarded-for']
  if forwardedIpsStr
    # 'x-forwarded-for' header may return multiple IP addresses in
    # the format: "client IP, proxy 1 IP, proxy 2 IP" so take the
    # the first one
    forwardedIps = forwardedIpsStr.split(',')
    ipAddress = forwardedIps[0]

  if not ipAddress
    # If request was not forwarded
    ipAddress = request.connection.remoteAddress

  ipAddress

module.exports =
  name: "Webhook Inspector"

  http_listen: (request, response, logger) ->
    if /\/webhook-inspector/i.test request.url
      console.log "/webhook-inspector got a #{request.method} message!"
      console.log util.inspect(request)

      clientIp = getClientIp request

      response.writeHead 200, {'Content-Type': 'text/html'}
      response.end "okay #{ clientIp }"

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

  listen: () ->


http = require 'http'
{_}  = require 'underscore'

module.exports =
  curl: (options, callback) ->
    options = _.defaults options,
      method: 'GET'
      port: 80

    client = http.createClient options.port, options.host
    request = client.request options.method, options.path, host: options.host
    request.end()

    request.on 'response', (response) ->
      data = ''
      response.on 'data', (chunk) ->
        data += chunk
      response.on 'end', () ->
        callback data

  getClientIp: (request) ->
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

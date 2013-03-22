http = require 'http'
{_}  = require 'underscore'
qs   = require 'querystring'

module.exports =
  curl: (options, callback) ->
    options = _.defaults options,
      method: 'GET'
      port: 80
      headers:
        'User-Agent': "pat the campfire bot, https://github.com/abachman/pat-the-campfire-bot"

    # host: A domain name or IP address of the server to issue the request to. Defaults to 'localhost'.
    # hostname: To support url.parse() hostname is preferred over host
    # port: Port of remote server. Defaults to 80.
    # localAddress: Local interface to bind for network connections.
    # socketPath: Unix Domain Socket (use one of host:port or socketPath)
    # method: A string specifying the HTTP request method. Defaults to 'GET'.
    # path: Request path. Defaults to '/'. Should include query string if any. E.G. '/index.html?page=12'
    # headers: An object containing request headers.
    # auth: Basic authentication i.e. 'user:password' to compute an Authorization header.
    # agent: Controls Agent behavior. When an Agent is used request will default to Connection: keep-alive. Possible values:


    if options.params?
      options.path = options.path + "?" + qs.stringify(options.params)

    console.log "making request with options: " + JSON.stringify(options)

    request = http.request options, (response) ->
      # response.setEncoding('utf8');

      console.log('STATUS:  ' + response.statusCode)
      console.log('HEADERS: ' + JSON.stringify(response.headers))

      data = ''
      response.on 'data', (chunk) ->
        data += chunk
      response.on 'end', () ->
        callback data

    request.end()

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

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

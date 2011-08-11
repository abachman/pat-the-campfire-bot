qs     = require 'querystring'
{curl} = require '../vendor/simple_http'

module.exports = 
  name: "It's This For That"
  listen: (message, room, logger) ->
    body = message.body

    if (/pat/i.test(body) && (/a business/i.test(body) || /business idea/i.test(body))) || /^!biz/.test(body)
      console.log "finding a new business idea"
      options = 
        host: 'itsthisforthat.com'
        path: '/api.php?text'

      curl options, (data) ->
        if data.length
          room.speak data.trim(), logger

util = require('util')
curl = require('../vendor/simple_http').curl
qs   = require('querystring')

adjectivenoun_host = 'adjectivenoun.me'
adjectivenoun_port = 80

module.exports =
  name: "Anagrammit"
  listen: (message, room, logger) ->
    body = message.body

    commit_matcher = /commit\/([a-z0-9]+)\)/

    if commit_matcher.test(body)
      hash = commit_matcher.exec(body)[1]

      unless hash && hash.length
        return

      console.log "getting adjectivenoun for \"#{ hash }\""

      options =
        host: adjectivenoun_host
        port: adjectivenoun_port
        path: "/#{ hash }.txt"

      curl options, (data) ->
        console.log "got a response from adjective noun: \"#{ data }\""
        room.speak "\"#{ data.trim() }\""

# pull results from anagrammit web service
util = require('util')
curl = require('../vendor/simple_http').curl
qs   = require('querystring')

# if you're using anagrammit, make sure you add the same api token to both heroku envs
anagrammit_token = process.env.ANAGRAMMIT_API_TOKEN || 'dev'
anagrammit_host = process.env.ANAGRAMMIT_HOST || 'localhost'
anagrammit_port = process.env.ANAGRAMMIT_PORT || 3000

module.exports =
  listen: (message, room, logger) ->
    body = message.body

    if /pat/i.test(body) && /anagram/i.test(body)
      phrase = body.match(/"([^\"]*)"/)

      unless phrase && phrase[1].length
        room.speak "You'll have to give me more than that. Make sure you include a phrase in double quotes. e.g.,  \"helloworld\"", logger
        return

      phrase = phrase[1]

      console.log "getting anagrams of \"#{ phrase }\""
      console.log "from #{anagrammit_host}:#{anagrammit_port}/token=#{anagrammit_token}"

      options =
        host: anagrammit_host
        port: anagrammit_port
        path: "/generate?phrase=#{ qs.escape(phrase) }&token=#{ qs.escape(anagrammit_token) }"

      curl options, (data) ->
        console.log "results are ready! #{ data }"

        results = JSON.parse(data)
        if /success/i.test(results.status)
          room.speak "#{ results.results.length } results:"
          room.paste results.results.join(' \n'), logger
        else
          room.speak "there was a problem :( \"#{ results.message }\"", logger

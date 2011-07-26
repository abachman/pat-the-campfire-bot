# pull results from anagrammit web service
http = require('http')
util = require('util')
qs   = require('querystring')

# if you're using anagrammit, make sure you add the same api token to both heroku envs
anagrammit_token = process.env.ANAGRAMMIT_API_TOKEN || 'dev'
anagrammit_host = process.env.ANAGRAMMIT_HOST || 'localhost'
anagrammit_port = process.env.ANAGRAMMIT_PORT || 3000

module.exports = 
  listen: (message, room, logger) ->
    body = message.body

    if /pat/i.test(body) && /anagram/i.test(body)
      phrase = body.match(/"([^\"]+)"/)[1]

      console.log "getting anagrams of \"#{ phrase }\""

      if phrase.length
        anagrammit_client = http.createClient anagrammit_port, anagrammit_host
        options =
          method  : 'GET'
          path    : "/generate?phrase=#{ qs.escape(phrase) }&token=#{ qs.escape(anagrammit_token) }"
        
        request = anagrammit_client.request options.method, options.path
        request.end()
        request.on 'response', (response) ->
          data = ''
          response.on 'data', (chunk) ->
            data += chunk
          response.on 'end', () ->
            results = JSON.parse(data)
            if /success/i.test(results.status)
              room.speak "#{ results.results.length } results:"
              room.speak results.results.join('\n'), logger
            else
              room.speak "there was a problem :( \"#{ results.message }\"", logger

        # stuff
      else
        room.speak "You'll have to give me more than that. Make sure you include a phrase in double quotes. e.g.,  \"helloworld\"", logger
    




util       = require('util')
curl       = require('../vendor/simple_http').curl
SpeakOnce  = require('../vendor/speak_once').SpeakOnce
_          = require('underscore')._
qs         = require('querystring')

# XML message from logentries's post-to-url alert service
#

module.exports =
  name: "Logentries"

  # receive logentries post hook
  http_listen: (request, response, logger) ->
    if /\/logentries/i.test request.url
      if /get/i.test request.method
        # GET (test)
        if process.env.node_env isnt 'production'
          response.writeHead 200, {'Content-Type': 'text/html'}
          response.end "
            <form action='/commit' method='post'>
              <textarea rows='40' cols='80' id='payload' name='payload'></textarea>
              <br />
              <input type='submit' value='post' />
            </form>
          "
          return true
        else
          return false

      # POST
      # get all data
      data = ""

      request.on 'data', (incoming) ->
       data += incoming

      request.on 'end', ->
        payload = qs.parse(data).payload
        console.log "[logentries] recieved data stream (#{typeof data}): #{ data }"
        console.log "[logentries] recieved payload (#{typeof payload}): #{ payload }"

        # output
        response.writeHead 200, {'Content-Type': 'text/plain'}

        imcoming = null
        try
          incoming = JSON.parse payload
        catch e
          console.log "[logentries] error parsing commit data, bailing. :("
          console.log "[logentries] #{ e.message }"
          return false

        try
          console.log "[logentries] parsed incoming"
          console.log utils.inspect(incoming)

          new SpeakOnce process.env.campfire_logging_room, (room) ->
            try
              room.speak "[logentries says] #{util.inspect(incoming)}\""
            catch ex
              console.log "[logentries] error trying to post logentries incoming: #{ ex.message }"
          response.end ''
        catch ex
          console.log "[logentries] ERROR: #{ ex.message }"
          response.end ex.message
        return true
      return true

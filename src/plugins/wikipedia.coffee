# pull results from anagrammit web service
util = require 'util'
{_}  = require 'underscore'
qs   = require 'querystring'

{curl} = require '../vendor/simple_http'

wikipedia_host = 'en.wikipedia.org'

module.exports =
  name: "Wikipedia"

  listen: (message, room, logger) ->
    body = message.body

    patterns = [
      /look up(:)? (.+)$/i
      /what is( a| an)? ([^?]+)\??$/i
    ]

    if /^pat/i.test(body) && _.any(patterns, (pattern) -> pattern.test(body))
      pattern = _.find(patterns, (pattern) -> pattern.test(body))
      phrase  = body.match(pattern)

      unless phrase && phrase[2].length
        room.speak "I can't tell what you want me to look up :(", logger
        return

      phrase = phrase[2]

      quoted = /"([^"]+)"/

      if quoted.test(phrase)
        phrase = phrase.match(quoted)[1]

      console.log "looking up \"#{ phrase }\" on wikipedia"

      # "http://en.wikipedia.org/w/api.php?action=query&titles=Baseball&format=json&prop=extracts&exsentences=6"
      # {
      #   "query": {
      #     "pages": {
      #       "3850": {
      #         "pageid": 3850,
      #         "ns": 0,
      #         "title": "Baseball",
      #         "extract": "<p><b>Baseball</b> is a bat-and-ball sport ... </p>"
      #       }
      #     }
      #   }
      # }

      options =
        host    : wikipedia_host
        path    : "/w/api.php"
        params:
          action: 'query'
          format: 'json'
          prop: 'extracts'
          exintro: true
          explaintext: true
          titles: phrase

      console.log "hitting wikipedia with params: #{ qs.stringify(options.params) }"

      curl options, (data) ->
        console.log "RAW RESPONSE:"
        console.log data

        try
          results = JSON.parse(data)

          out = ""

          console.log "got pages " + JSON.stringify(results.query.pages)

          for page, content of results.query.pages
            console.log "got response on page #{ page }"
            console.log util.inspect(content)

            if content.extract?
              room.speak content.extract, logger
              wikiUrl = "http://#{wikipedia_host}/wiki/#{qs.escape(content.title.replace(' ','_'))}"
              room.speak wikiUrl, logger
            else if content.invalid?
              room.speak "Wikipedia didn't know how to handle that one :(", logger
            else if content.missing?
              room.speak "I checked Wikipedia but couldn't find anything, sorry.", logger

        catch e
          room.speak "there was a problem :( \"#{ e.message }\"", logger


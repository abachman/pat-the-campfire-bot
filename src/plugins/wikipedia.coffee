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

    if /pat/i.test(body) && /look up:/i.test(body)
      phrase = body.match(/: (.*)$/)

      unless phrase && phrase[1].length
        room.speak "I can't tell what you want me to look up :(", logger
        return

      phrase = phrase[1]

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
              room.speak wikiUrl

            if content.invalid?
              throw "Wikipedia didn't know how to handle that one :("

          # _forms.forEach (form) ->
          #   if results[form].syn.length
          #     out += form_template({form: form, results: results[form].syn.join(", ")})
          #     out += "\n\n"

          # if out.length
          #   room.speak "\"#{ phrase }\""
          #   room.paste out, logger
          # else
          #   room.speak "I didn't get any results for #{ phrase }"

        catch e
          room.speak "there was a problem :( \"#{ e.message }\"", logger


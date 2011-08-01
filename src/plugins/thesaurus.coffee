# pull results from anagrammit web service
http = require('http')
util = require('util')
{_}  = require 'underscore'
qs   = require('querystring')

# if you're using http://words.bighugelabs.com/
thesaurus_token = process.env.THESAURUS_API_TOKEN
thesaurus_host  = 'words.bighugelabs.com'
thesaurus_port  = 80

module.exports =
  listen: (message, room, logger) ->
    body = message.body

    return unless thesaurus_token

    if /pat/i.test(body) && (/thesaurus/i.test(body) || /another word for/i.test(body) || /synonym/i.test(body))
      phrase = body.match(/"([^\"]*)"/)

      unless phrase && phrase[1].length
        room.speak "You'll have to give me more than that. Make sure you include a word in double quotes. e.g.,  \"helloworld\"", logger
        return

      phrase = phrase[1]

      console.log "getting synonyms of \"#{ phrase }\""
      console.log "from #{thesaurus_host}:#{thesaurus_port}/api/2/#{ qs.escape(thesaurus_token) }/#{ qs.escape(phrase) }/json"

      # http://words.bighugelabs.com/api/2/$API_TOKEN/show/json
      #
      # {
      #   "noun":
      #     {"syn":["display","appearance","amusement","demo","demonstration","entertainment","feigning","pretence","pretending","pretense","simulation","social event"]},
      #   "verb":
      #     {"syn":["show","demo","exhibit","present","demonstrate","prove","establish","shew","testify","bear witness","evidence","picture","depict","render","express","evince","indicate","point","show up","read","register","record","usher","affirm","appear","communicate","conduct","confirm","convey","corroborate","direct","display","guide","impart","inform","interpret","lead","pass","pass along","pass on","put across","race","represent","reveal","run","substantiate","support","sustain","take"],
      #      "ant":["disprove","hide"],
      #      "rel":["show off"]
      #     }
      # }

      form_template = _.template "<%= form %>: <%= results %>"

      thesaurus_client = http.createClient thesaurus_port, thesaurus_host
      options =
        method  : 'GET'
        path    : "/api/2/#{ qs.escape(thesaurus_token) }/#{ qs.escape(phrase) }/json"

      request = thesaurus_client.request options.method, options.path, host: thesaurus_host
      request.end()
      request.on 'response', (response) ->
        data = ''
        response.on 'data', (chunk) ->
          data += chunk
        response.on 'end', () ->
          try
            results = JSON.parse(data)

            out = ""
            _forms = _.keys(results)

            _forms.forEach (form) ->
              if results[form].syn.length
                out += form_template({form: form, results: results[form].syn.join(", ")})
                out += "\n\n"

            if out.length
              room.speak "\"#{ phrase }\""
              room.paste out, logger
            else
              room.speak "I didn't get any results for #{ phrase }"

          catch e
            room.speak "there was a problem :( \"#{ e.message }\"", logger


util = require('util')
curl = require('../vendor/simple_http').curl
qs   = require('querystring')

adjectivenoun_host = 'adjectivenoun.me'
adjectivenoun_port = 80

module.exports =
  name: "Anagrammit"

  # receive github post hook
  http_listen: (request, response) ->
    if /\/commit/i.test request.url
      # get all data
      commit = ""

      request.on 'data', (data)->
        commit += data

      request.on 'end', ->
        console.log "[github] recieved data:\n#{ commit }"

        console.log "[github] payload: #{ util.inspect( JSON.parse( qs.parse(commit).payload ) ) }"

        # {
        #   "before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
        #   "repository": {
        #     "url": "http://github.com/defunkt/github",
        #     "name": "github",
        #     "description": "You're lookin' at it.",
        #     "watchers": 5,
        #     "forks": 2,
        #     "private": 1,
        #     "owner": {
        #       "email": "chris@ozmm.org",
        #       "name": "defunkt"
        #     }
        #   },
        #   "commits": [
        #     {
        #       "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
        #       "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
        #       "author": {
        #         "email": "chris@ozmm.org",
        #         "name": "Chris Wanstrath"
        #       },
        #       "message": "okay i give in",
        #       "timestamp": "2008-02-15T14:57:17-08:00",
        #       "added": ["filepath.rb"]
        #     },
        #     {
        #       "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
        #       "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
        #       "author": {
        #         "email": "chris@ozmm.org",
        #         "name": "Chris Wanstrath"
        #       },
        #       "message": "update pricing a tad",
        #       "timestamp": "2008-02-15T14:36:34-08:00"
        #     }
        #   ],
        #   "after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
        #   "ref": "refs/heads/master"
        # }

        # json
        # response.writeHead 200, {'Content-Type': 'application/json'}

        # # output
        # response.end JSON.stringify(data: commit, a: 1, b: 2, c: 3)


      return true

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

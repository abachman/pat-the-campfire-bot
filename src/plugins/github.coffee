util       = require('util')
curl       = require('../vendor/simple_http').curl
SpeakOnce  = require('../vendor/speak_once').SpeakOnce
{_}        = require('underscore')
qs         = require('querystring')

# JSON message from github's post-url service
# {
#   "pusher": {
#     "email": "something@some.com",
#     "name": "defunkt"
#   },
#   "compare": "http://github.com/own/proj/compare/123...432",
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

# Get AdjectiveNoun for a given checkin
class AdjectiveNoun
  get: (phrase, callback) ->
    options =
      host: 'adjectivenoun.me'
      port: 80
      path: "/#{ phrase }.txt"

    curl options, (data) ->
      callback data.trim()

module.exports =
  name: "Github"

  # receive github post hook
  http_listen: (request, response, logger) ->
    if /\/commit/i.test request.url
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
        console.log "[github] recieved data (#{typeof payload}): #{ payload }"

        # output
        response.writeHead 200, {'Content-Type': 'text/plain'}

        commit = null
        try
          commit = JSON.parse payload
        catch ex
          console.log "[github] error parsing commit data, bailing. :("
          console.log "[github] #{ ex.message }"
          response.end ex.message
          return false

        try
          hash_token   = /^(.{7})/
          before       = commit.before
          before_token = hash_token.exec(before)[1]
          after        = commit.after
          after_token  = hash_token.exec(after)[1]
          qty          = commit.commits.length
          project      = commit.repository.name
          branch       = if /\//.test(commit.ref) then /\/([^/]*)$/.exec(commit.ref)[1] else commit.ref

          link_to_commit = (hash) ->
            commit.repository.url + "/commit/#{ hash }"

          console.log "[github] parsed commit #{ commit.repository.url }/commit/#{after_token}"

          # get release name
          (new AdjectiveNoun).get after_token, (release_name) ->
            new SpeakOnce (room) ->
              try
                if qty == 1
                  # a single commit
                  c = commit.commits[0]
                  room.speak "[#{ project }/#{ branch }] #{ c.message } - #{ c.author.name } (#{ link_to_commit(after) }) \n\ncurrent release #{ after_token }: \"#{release_name}\"",
                    logger
                else if qty > 1
                  # a list of commits
                  compare_url = commit.compare # "#{ commit.repository.url }/compare/#{ before_token }...#{ after_token }"
                  room.speak "[#{ project }] #{ commit.pusher.name } pushed #{qty} commits to #{ branch }: #{ compare_url }"
                  commit.commits.forEach (c) ->
                    room.speak "[#{ project }/#{ branch }] #{ c.message } - #{ c.author.name }",
                      logger
                  room.speak "[#{project}/#{ branch }] current release #{ after_token }: \"#{release_name}\""
              catch ex
                console.log "error trying to post github commit: #{ ex.message }"
          response.end ''
        catch ex
          console.log "[github] ERROR: #{ ex.message }"
          console.log ex.stack
          response.end ex.message
        return true
      return true

  listen: (message, room, logger) ->
    body = message.body

    commit_matcher = /commit\/([a-z0-9]+)\)/

    if commit_matcher.test(body)
      hash = commit_matcher.exec(body)[1]

      unless hash && hash.length
        return

      console.log "getting adjectivenoun for \"#{ hash }\""

      (new AdjectiveNoun).get hash, (data) ->
        console.log "got a response from adjective noun: \"#{ data }\""
        room.speak "\"#{ data }\""

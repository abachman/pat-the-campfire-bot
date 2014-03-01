util      = require('util')
SpeakOnce = require('../vendor/speak_once').SpeakOnce
qs        = require('querystring')
{_}       = require('underscore')

EXCUSES = [
  [
    "What ya got there's"
    "Sounds like"
    "Could be"
    "Might be"
    "It may be"
    "It's likely to be"
    "I'm afraid it's"
    "Look out for"
    "This sounds like"
    "Your problem is"
    "Could be user error, could also be"
  ]
  [
    'Multiplexed'
    'Intermittant'
    'Synchronous'
    'Unreplicatable'
    'Asynchronous'
    'Resignalled'
    'Extraneous'
    'Dereferenced'
    'Redundant'
  ],
  [
    'Registry'
    'Configuration'
    'Systems'
    'Hardware'
    'Software'
    'Firmware'
    'Backplane'
    'Transmission'
    'Reception'
  ],
  [
    'Interruption'
    'Dereferencing'
    'Reclock'
    'Incompatibility'
    'Stackdump'
    'Lockout'
    'Override'
    'Invalidation'
    'Desynchronisation'
  ],
  [
    'Condition'
    'Error'
    'Problem'
    'Warning'
    'Signal'
    'Flag'
    'Malfunction'
    'Failure'
    'Indication'
  ]
]

class Excuse
  generate: ->
    init = _.first(_.shuffle(EXCUSES[0]))
    rest = _.map(EXCUSES.slice(1), (subList) ->
      _.first(_.shuffle(subList))
    ).join(' ')

    if /^[aeiou]/i.test(rest)
      init += ' an '
    else
      init += ' a '

    init + rest

module.exports =
  name: "excuses"
  http_listen: (request, response, logger) ->
    if /\/excuse$/i.test request.url
      # output
      console.log "generating excuse"
      response.writeHead 200, {'Content-Type': 'text/plain'}
      response.end (new Excuse).generate()
      console.log "DONE!"

  listen: (message, room, logger) ->
    body = message.body

    if /pat/i.test(body) and (/an excuse/i.test(body) or /the excuse/i.test(body) or /my excuse/i.test(body) or /our excuse/i.test(body) or /some excuse/i.test(body))
      console.log "generating excuse"
      room.speak (new Excuse).generate(), logger


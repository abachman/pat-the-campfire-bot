#  mess around with your helpspot installation

_ = require('underscore')

logger = ( d ) ->
  try
    console.log "#{d.message.created_at}: #{d.message.body}"

patterns = []

# link directly to a support request. Link template is an env variable with $
# where the request ID should be.
patterns.push
  regex: /(^|[^a-zA-Z0-9])(\d{5})($|[^a-zA-Z0-9])/ # try to avoid matching git hashes
  template: process.env.helpspot_link_template

module.exports = 
  listen: (msg, room, env) ->
    # ignore commands
    return if /^!/.test(msg.body)

    _.each patterns, (pattern) ->
      if pattern.regex.test(msg.body)
        console.log "posting helpspot link: #{ msg.body.matching(pattern.regex)[2] }"
        room.speak pattern.template.replace('$', msg.body.match(pattern.regex)[2]), logger

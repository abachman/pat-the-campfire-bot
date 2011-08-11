echo_matcher = /^!echo\b(.*)/i

module.exports = 
  name: "echo"
  listen: (message, room, logger) ->
    body = message.body

    if echo_matcher.test(body)
      console.log "echoing"
      room.speak echo_matcher.exec(body)[1], logger

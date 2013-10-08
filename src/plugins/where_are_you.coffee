module.exports =
  name: "Where are you?"

  listen: (message, room, logger) ->
    body = message.body

    if /pat/i.test(body) && /where are you\?/i.test(body)
      room.speak "I am in #{ process.cwd() }", logger


{_}    = require 'underscore'
{User} = require '../store'

phrases = [
  { regex: /pat\?/, msg: "yeah, I'm here" }
  { regex: /deal with it/,  msg: "http://s3.amazonaws.com/gif.ly/gifs/490/original.gif?1294726461" }
  { regex: /noob/i, msg: 'http://www.marriedtothesea.com/022310/i-hate-thinking.gif' }
  { regex: /imo/i,  msg: [ "http://s3.amazonaws.com/gif.ly/gifs/485/original.gif?1294425077", "well, that's just, like, your opinion, man."] }
  { 
    regex: /^(hi|hello|hey|yo )/i
    precedent: /pat/i
    msg: _.template("<%= match %> yourself, <%= user.name %>") 
  }
  { 
    regex: /morning/i
    precedent: /pat/i
    msg: _.template("Good morning to you too, <%= user.name %>!") 
  }
  { 
    regex: /afternoon/i
    precedent: /pat/i
    msg: "a pleasant afternoon to you, as well"  
  }
  { 
    regex: /night/i
    precedent: /pat/i
    msg: "it's probably not nighttime where i am"  
  }
]

api =
  logger: (d) ->
    try
      console.log "#{d.message.created_at}: #{d.message.body}"

  phrases: phrases

  listen: ( message, room ) ->
    # loop through the static phrases
    api.phrases.forEach (phrase) ->
      if phrase.precedent
        return unless phrase.precedent.test(message.body)
      return unless phrase.regex.test(message.body)

      if _.isArray( phrase.msg )
        phrase.msg.forEach (msg) ->
          room.speak msg, api.logger
      else if _.isFunction(phrase.msg)
        match = message.body.match(phrase.regex)[1]

        # find the user who spoke and pass them along
        User.findOne {user_id: message.user_id}, (err, user) ->
          if user 
            room.speak phrase.msg({match: match, user: user}), api.logger
          else
            room.speak phrase.msg({match: match, user: {}}), api.logger
      else
        room.speak phrase.msg, api.logger

      phrase.callback() if _.isFunction( phrase.callback )

module.exports = api


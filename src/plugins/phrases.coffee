{_} = require 'underscore'
util = require 'util'
{User, Phrase} = require '../store'

phrases = [
  { regex: /\bpat\?/i, msg: "yeah, I'm here" }
  { regex: /\bnoob\b/i, msg: 'http://www.marriedtothesea.com/022310/i-hate-thinking.gif' }
  { regex: /morning/i, precedent: /\bpat\b/i, msg: _.template("Good morning to you too, <%= user.name %>!") }
  { regex: /night/i, precedent: /\bpat\b/i, msg: "it's probably not nighttime where i am" }
]

# response with precedent
phrases.push
  regex: /afternoon/i
  precedent: /\bpat\b/i
  msg: "a pleasant afternoon to you, as well"

# templated response. Template messages get `match` and `user` variables.
phrases.push
  precedent: /\bpat\b/i
  regex: /^(hi|hello|hey|yo )/i
  msg: _.template("<%= match %> yourself, <%= user.name %>")

# single message response
phrases.push
  regex: /deal with it/i
  msg: "http://s3.amazonaws.com/gif.ly/gifs/490/original.gif?1294726461"

# multiple message response
phrases.push
  regex: /\bimo\b/i
  msg: [ "http://s3.amazonaws.com/gif.ly/gifs/485/original.gif?1294425077", "well, that's just, like, your opinion, man."]

# choose one response
phrases.push 
  regex: /do not want/i
  msg: [ 
    "http://theducks.org/pictures/do-not-want-dog.jpg"
    "http://img69.imageshack.us/img69/3626/gatito13bj0.gif"
    "http://icanhascheezburger.files.wordpress.com/2007/03/captions03211.jpg?w=500&h=332"
    "http://icanhascheezburger.files.wordpress.com/2007/04/do-not-want.jpg?w=500&h=430"
    "http://wealsoran.com/music/uploaded_images/images_do_not_want-741689.jpg"
  ]
  choice: true

class Phrases
  constructor: (static_phrases) -> 
    @static_phrases = static_phrases

    @load_phrases()
    
    @re_matcher = /(\/[^/]+\/[a-z]{0,3})/i
    @phrase_matcher = /"([^\"]*)"/i

    # reuse the re_matcher
    remove_matcher = @re_matcher.toString()
    remove_matcher = remove_matcher.substr(1, remove_matcher.length - 3) # get rid of leading / and trailing /i
    @remove_matcher = new RegExp("-" + remove_matcher)
  
  load_phrases: ->
    @phrases = []

    # first the static phrases
    @static_phrases.forEach (phrase) =>
      @phrases.push phrase

    # learned responses. load on require
    Phrase.find {}, (err, stored_phrases) =>
      stored_phrases.forEach (phrase) =>
        # console.log "Loading from mongo: #{ util.inspect(phrase) }"
        if phrase.pattern && phrase.pattern.length
          try
            phr = regex:  new RegExp(phrase.pattern, phrase.modifiers)
          catch e
            console.log "Couldn't load invalid regex /#{ phrase.pattern }/#{phrase.modifiers}! #{ e.message }"
            continue
          if phrase.choice
            # chooser
            phr.choice = true
            phr.msg    = JSON.parse(phrase.message)
          else
            # bare phrase
            phr.msg = phrase.message
          @phrases.push phr
      console.log "[Phrases] I know #{ @phrases.length } phrases: #{ @all_phrases() }"

  logger: (d) ->
    try
      console.log "#{d.message.created_at}: #{d.message.body}"

  # return phrase identifiers
  all_phrases: -> 
    _.map(@phrases, (phrase) -> phrase.regex.toString()).join(', ')

  tell_all: (room) ->
    console.log "[Phrases] I know #{ @phrases.length } phrases: #{ @all_phrases() }"
    room.speak "I know #{ @phrases.length } phrases: #{ @all_phrases() }", @logger

  get_isolated_pattern: (pattern) ->
    _leading  = /^\//
    _trailing = /\/([a-z]{0,3})$/

    mods = ""
    mods = _trailing.exec(pattern)[1] if _trailing.test(pattern)

    return {
      pattern: pattern.replace(_leading, '').replace(_trailing, '')
      modifiers: mods
    }

  save_phrase: (phrase_record, message, room) -> 
    phrase_record.save (err, new_phrase) => 
      User.findOne {user_id: message.user_id}, (err, user) =>
        response = ""
        if user
          response = "Thanks #{ user.name.split(' ')[0] }!  "

        response += "From now on, if anyone says #{ new_phrase.pattern }, "
        if new_phrase.choice
          phrases = JSON.parse new_phrase.message
          response += "I'll choose from #{ phrases.length } responses"
        else
          response += "I'll say \"#{ new_phrase.message }\""

        room.speak response, @logger
        @load_phrases()

  add_phrase: (regex, phrase, message, room) ->
    # full_pattern is a string like "/all that/i"
    {pattern, modifiers} = @get_isolated_pattern regex

    try 
      new RegExp(pattern, modifiers)
    catch e
      console.log "invalid regex detected: /#{pattern}/#{modifiers} : #{e.message}"
      room.speak "That was a bad regex :(", @logger

    console.log "I got: {phrase: \"#{ phrase }\", pattern: \"#{ pattern }\", modifiers: \"#{ modifiers }\"}"

    # do we already have this one?
    Phrase.findOne {pattern: pattern, modifiers: modifiers}, (err, existing_phrase) =>
      if existing_phrase
        if existing_phrase.choice 
          # already a choce phrase
          _phrases = JSON.parse(existing_phrase.message)
          _phrases.push phrase
          existing_phrase.message = JSON.stringify _phrases
        else
          existing_phrase.message = JSON.stringify [existing_phrase.message, phrase]
          existing_phrase.choice  = true

        @save_phrase existing_phrase, message, room

        # add new response to collection and set choice to true
        # room.speak "I already respond to /#{ pattern }/#{ modifiers }, sorry :(", @logger
        return 

      # add phrase to store
      _phrase = new Phrase
        pattern: pattern
        modifiers: modifiers
        user_id: message.user_id
        message: phrase

      @save_phrase _phrase, message, room

  remove_phrase: (regex, room) ->
    {pattern, modifiers} = @get_isolated_pattern(regex)
    Phrase.findOne {pattern: pattern, modifiers: modifiers}, (err, phrase) =>
      if err or phrase is null
        room.speak "I couldn't find a phrase matching /#{ pattern }/#{ modifiers }"
      else
        phrase.remove (err, p) => 
          room.speak "I've removed a phrase matching /#{ pattern }/#{ modifiers }"
          @load_phrases()

  match_phrase: (message, room) ->
    # loop through the static phrases, find a matching reponse
    if /pat/i.test(message.body) && /what.*know\??$/i.test(message.body)
      @tell_all(room)
      return

    @phrases.forEach (phrase) =>
      if phrase.precedent
        return unless phrase.precedent.test(message.body)

      return unless phrase.regex.test(message.body)

      console.log "matched #{ message.body } with #{ phrase.regex.toString() }"

      if _.isArray( phrase.msg )
        if phrase.choice
          choose = Math.floor(Math.random() * phrase.msg.length)
          room.speak phrase.msg[choose], @logger
        else
          phrase.msg.forEach (msg) =>
            room.speak msg, @logger
      else if _.isFunction(phrase.msg)
        match = message.body.match(phrase.regex)[1]
        # find the user who spoke and pass them along
        User.findOne {user_id: message.user_id}, (err, user) =>
          if user 
            room.speak phrase.msg({match: match, user: user}), @logger
          else
            room.speak phrase.msg({match: match, user: {}}), @logger
      else
        console.log "speaking the bare phrase: #{ phrase.msg }"
        room.speak phrase.msg, @logger
      phrase.callback() if _.isFunction( phrase.callback )

  listen: (message, room) ->
    body = message.body

    # adder
    if /\bpat\b/i.test(body) 
      if @re_matcher.test(body) && @phrase_matcher.test(body)
        console.log "add a phrase"
        @add_phrase @re_matcher.exec(body)[1], @phrase_matcher.exec(body)[1], message, room
        return
      else if @remove_matcher.test(body)
        console.log "remove a phrase"
        @remove_phrase @re_matcher.exec(body)[1], room
        return
      
    @match_phrase(message, room)

module.exports = new Phrases(phrases)


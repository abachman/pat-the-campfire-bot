Google    = require('../vendor/google')
unescape  = require('../vendor/unescape')
_         = require('underscore')

google    = new Google()

logger = ( d ) ->
  try
    console.log "#{d.message.created_at}: #{d.message.body}"
  catch e
    console.log(d)

extract_params = (param) ->
  arg_exp = /\+[0-9]+/
  # get count
  if arg_exp.test(param)
    count = arg_exp.exec(param)[0]
    count = count.replace('+', '')
    count = parseInt(count)
  else
    count = 1

  # get query
  query = param.replace arg_exp, ''

  {
    count: count
    query: query
  }

formatted_result = (result) ->
  buffer = new Buffer("#{result.titleNoFormatting} :: #{result.unescapedUrl}", "ascii")
  buffer.toString().replace('–', '-')

module.exports =
  listen: ( msg, room, env ) ->
    g_exp   = /^!g\s+([^#@]+)?$/
    mdc_exp = /^!mdc ([^#@]+)(?:\s*#([1-9]))?$/
    yt_exp  = /^!yt ([^#@]+)(?:\s*#([1-9]))?$/
    jq_exp  = /^!jq ([^#@]+)(?:\s*#([1-9]))?$/
    w_exp   = /^!w(eather)? ([^#@]+)(?:\s*#([1-9]))?$/

    if g_exp.test msg.body
      param = g_exp.exec(msg.body)[1]
      {count, query} = extract_params param

      google.search query, ( results ) ->
        if results.length
          console.log "GOT RESULTS!"
          console.dir results
          if count > 1 && results.length >= count
            out = []
            for n in [0..(count-1)]
              out.push formatted_result(results[n])
            console.log "returning:"
            console.log '----'
            console.log out.join("\n")
            console.log '----'
            room.paste out.join("\n"), logger  
          else
            room.speak formatted_result(results[0]), logger
        else
          room.speak "Sorry, no results for \"#{ param }\"", logger

    if jq_exp.test msg.body
      param = msg.body.match(jq_exp)[1] + ' site:api.jquery.com'
      google.search param, ( results ) ->
        if results.length
          room.speak formatted_result(results[0]), logger
        else
          room.speak "Sorry, no results for \"#{ param }\"", logger

    if mdc_exp.test msg.body
      param = msg.body.match(mdc_exp)[1] + ' site:developer.mozilla.org'
      google.search param, ( results ) ->
        if results.length
          room.speak formatted_result(results[0]), logger
        else
          room.speak "Sorry, no results for \"#{ param }\"", logger

    if yt_exp.test msg.body
      param = msg.body.match(yt_exp)[1] + ' site:youtube.com'
      google.search param, ( results ) ->
        if results.length
          # room.speak "#{results[0].titleNoFormatting.replace('–', '-')}", logger
          room.speak "#{results[0].unescapedUrl}", logger
        else
          room.speak "Sorry, no results for \"#{ param }\"", logger
    
    if w_exp.test msg.body
      param = msg.body.match(w_exp)[2]
      console.log "[Search] sending #{ param } to google api"
      google.weather param, ( results ) ->
        if results.city.length > 0
          weather_template = "weather for #{ results.city }: #{ results.condition }, #{ results.temp_f } F / #{ results.temp_c } C, #{ results.humidity }" 
          console.log "returning: '#{ weather_template }'"
          room.speak weather_template, logger
        else
          room.speak "Sorry, no results for \"#{ param }\"", logger

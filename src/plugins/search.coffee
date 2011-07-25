Google    = require('./google')
unescape  = require('../vendor/unescape')
_         = require('underscore')

google    = new Google()

logger = ( d ) ->
  try
    console.log "#{d.message.created_at}: #{d.message.body}"
  catch e
    console.log(d)

module.exports =
  listen: ( msg, room, env ) ->
    g_exp   = /^!g ([^#@]+)?$/
    mdc_exp = /^!mdc ([^#@]+)(?:\s*#([1-9]))?$/
    yt_exp  = /^!yt ([^#@]+)(?:\s*#([1-9]))?$/
    jq_exp  = /^!jq ([^#@]+)(?:\s*#([1-9]))?$/
    w_exp   = /^!w(eather)? ([^#@]+)(?:\s*#([1-9]))?$/

    if g_exp.test msg.body
      param = msg.body.match(g_exp)[1]
      google.search param, ( results ) ->
        if results.length
          room.speak "#{results[0].titleNoFormatting} - #{results[0].unescapedUrl}", logger
        else
          room.speak "Sorry, no results for \"#{ param }\"", logger

    if jq_exp.test msg.body
      param = msg.body.match(jq_exp)[1] + ' site:api.jquery.com'
      google.search param, ( results ) ->
        if results.length
          room.speak "#{results[0].titleNoFormatting.replace('–', '-')} - #{results[0].unescapedUrl}", logger
        else
          room.speak "Sorry, no results for \"#{ param }\"", logger

    if mdc_exp.test msg.body
      param = msg.body.match(mdc_exp)[1] + ' site:developer.mozilla.org'
      google.search param, ( results ) ->
        if results.length
          room.speak "#{results[0].titleNoFormatting} - #{results[0].unescapedUrl}", logger
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

fs = require 'fs'
util = require 'util'
{_} = require 'underscore'

chat_responders = []
web_responders  = []

logger = (d) ->
  if d.message
    console.log "#{d.message.created_at}: #{d.message.body}"

class PluginNotifier
  constructor: (@plugins, @services) ->
  http_notify: (request, response) ->
    # only one response
    _.any(
      _.map(@services, (service) -> service.http_listen(request, response))
    )

  notify: (message, room) ->
    @plugins.forEach (plugin) ->
      plugin.listen(message, room, logger)

fs.readdirSync(__dirname).forEach (file) ->
  return if /^\./.test(file)

  # load it...
  plugin = require "./#{ file }"

  # if it seems like a legit plugin, keep it
  if plugin.listen
    console.log "loading plugin #{ plugin.name }"
    chat_responders.push plugin

  if plugin.http_listen
    console.log "loading plugin #{ plugin.name }"
    web_responders.push plugin

console.log "loading #{chat_responders.length} chat plugins and #{web_responders.length} http plugins from #{ __dirname }"

module.exports = new PluginNotifier(chat_responders, web_responders)

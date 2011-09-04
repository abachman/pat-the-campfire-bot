# Autoload all plugins in the current directory. Anything that exports a
# "listen" method is assumed to be a Campfire plugin, anything that exports an
# "http_listen" method is assumed to be an http request handler. The same
# plugin can provide both kinds of response capability.

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
    for service in @services
      # break if something responds
      return true if service.http_listen(request, response, logger)

  notify: (message, room) ->
    for plugin in @plugins
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
    console.log "loading service #{ plugin.name }"
    web_responders.push plugin

console.log "loading #{chat_responders.length} chat plugins and #{web_responders.length} http plugins from #{ __dirname }"

module.exports = new PluginNotifier(chat_responders, web_responders)

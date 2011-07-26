fs = require 'fs'
util = require 'util'

exports = []

logger = (d) ->
  console.log "#{d.message.created_at}: #{d.message.body}"

class PluginNotifier
  constructor: (@plugins) ->
  notify: (message, room) ->
    @plugins.forEach (plugin) ->
      plugin.listen(message, room, logger)

fs.readdirSync(__dirname).forEach (file) ->
  return if /^\./.test(file)

  # load it...
  plugin = require "./#{ file }"

  # if it seems like a legit plugin, keep it
  if plugin.listen
    exports.push plugin

console.log "loading #{exports.length} plugins from #{ __dirname }"

module.exports = new PluginNotifier(exports)

(function() {
  var PluginNotifier, chat_responders, fs, logger, util, web_responders, _;
  fs = require('fs');
  util = require('util');
  _ = require('underscore')._;
  chat_responders = [];
  web_responders = [];
  logger = function(d) {
    if (d.message) {
      return console.log("" + d.message.created_at + ": " + d.message.body);
    }
  };
  PluginNotifier = (function() {
    function PluginNotifier(plugins, services) {
      this.plugins = plugins;
      this.services = services;
    }
    PluginNotifier.prototype.http_notify = function(request, response) {
      return _.any(_.map(this.services, function(service) {
        return service.http_listen(request, response);
      }));
    };
    PluginNotifier.prototype.notify = function(message, room) {
      return this.plugins.forEach(function(plugin) {
        return plugin.listen(message, room, logger);
      });
    };
    return PluginNotifier;
  })();
  fs.readdirSync(__dirname).forEach(function(file) {
    var plugin;
    if (/^\./.test(file)) {
      return;
    }
    plugin = require("./" + file);
    if (plugin.listen) {
      console.log("loading plugin " + plugin.name);
      chat_responders.push(plugin);
    }
    if (plugin.http_listen) {
      console.log("loading plugin " + plugin.name);
      return web_responders.push(plugin);
    }
  });
  console.log("loading " + chat_responders.length + " chat plugins and " + web_responders.length + " http plugins from " + __dirname);
  module.exports = new PluginNotifier(chat_responders, web_responders);
}).call(this);

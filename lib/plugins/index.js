(function() {
  var PluginNotifier, exports, fs, util;
  fs = require('fs');
  util = require('util');
  exports = [];
  PluginNotifier = (function() {
    function PluginNotifier(plugins) {
      this.plugins = plugins;
    }
    PluginNotifier.prototype.notify = function(message, room) {
      return this.plugins.forEach(function(plugin) {
        return plugin.listen(message, room);
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
      return exports.push(plugin);
    }
  });
  console.log("loading " + exports.length + " plugins from " + __dirname);
  module.exports = new PluginNotifier(exports);
}).call(this);

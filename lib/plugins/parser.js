(function() {
  var PEG, parser;
  PEG = require('pegjs');
  parser = PEG.buildParser("start   = whole_commandwhole_command  = .*");
  module.exports = parser;
}).call(this);

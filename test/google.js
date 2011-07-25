var util = require('util');
var Google = require('./lib/google');

google = new Google();

google.weather('Baltimore, MD', function (results) {
  weather = "weather for " +  results.city  + ": " +  results.condition  + ", " +  results.temp_f  + " F / " +  results.temp_c + " C, " +  results.humidity  + ".";
  console.log(weather);
});

google.search('balloon animal', function (results) {
  phrase = results[0].titleNoFormatting + " - " + results[0].unescapedUrl;
  console.log(phrase);
});

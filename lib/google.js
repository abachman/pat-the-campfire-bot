(function() {
  var DomJS, Google, find_child_by_name, http, querystring, util;
  DomJS = require('dom-js').DomJS;
  http = require('http');
  util = require('util');
  querystring = require('querystring');
  find_child_by_name = function(_dom, name) {
    var child, result, _i, _len, _ref;
    if (name === _dom.name) {
      return _dom;
    } else if (_dom.children.length > 0) {
      _ref = _dom.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        result = find_child_by_name(child, name);
        if (result != null) {
          return result;
        }
      }
    }
  };
  Google = (function() {
    function Google() {}
    Google.prototype.search = function(query, callback) {
      var google_api_client, options, request;
      google_api_client = http.createClient(80, 'ajax.googleapis.com');
      console.log("[google#search] looking for " + query);
      options = {
        method: 'GET',
        path: '/ajax/services/search/web?v=1.0&q=' + querystring.escape(query),
        extra: {
          host: 'ajax.googleapis.com'
        }
      };
      request = google_api_client.request(options.method, options.path, options.extra);
      request.end();
      return request.on('response', function(response) {
        var data;
        if (typeof callback === 'function') {
          data = '';
          response.on('data', function(chunk) {
            return data += chunk;
          });
          return response.on('end', function() {
            var results;
            results = JSON.parse(data)['responseData']['results'];
            results.forEach(function(x) {
              x.titleNoFormatting = x.titleNoFormatting.replace(/&#([^\s]*)/g, function(m1, m2) {
                return String.fromCharCode(m2);
              }).replace(/&(nbsp|amp|quot|lt|gt)/g, function(m1, m2) {
                return {
                  'nbsp': ' ',
                  'amp': '&',
                  'quot': '"',
                  'lt': '<',
                  'gt': '>'
                }[m2];
              });
              return x;
            });
            return callback.call(this, results);
          });
        }
      });
    };
    Google.prototype.weather = function(query, callback) {
      var google_client, options, request;
      google_client = http.createClient(80, 'www.google.com');
      console.log("[google#weather] finding weather for " + query);
      options = {
        method: 'GET',
        path: '/ig/api?weather=' + querystring.escape(query)
      };
      request = google_client.request(options.method, options.path);
      request.end();
      return request.on('response', function(response) {
        var data;
        if (typeof callback === 'function') {
          data = '';
          response.on('data', function(chunk) {
            return data += chunk;
          });
          return response.on('end', function() {
            var domjs, results;
            results = {
              city: '',
              condition: '',
              temp_f: '',
              temp_c: '',
              humidity: ''
            };
            try {
              domjs = new DomJS();
              domjs.parse(data, function(err, dom) {
                var current, forecast;
                forecast = find_child_by_name(dom, 'forecast_information');
                current = find_child_by_name(dom, 'current_conditions');
                return results = {
                  city: find_child_by_name(forecast, 'city').attributes.data,
                  condition: find_child_by_name(current, 'condition').attributes.data,
                  temp_f: find_child_by_name(current, 'temp_f').attributes.data,
                  temp_c: find_child_by_name(current, 'temp_c').attributes.data,
                  humidity: find_child_by_name(current, 'humidity').attributes.data
                };
              });
            } catch (_e) {}
            console.log("ready with results for " + results.city);
            return callback(results);
          });
        }
      });
    };
    return Google;
  })();
  module.exports = Google;
}).call(this);

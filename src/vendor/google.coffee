# simple google search library
DomJS = require('dom-js').DomJS
http = require('http')
util = require('util')
querystring = require('querystring')

find_child_by_name = (_dom, name) ->
  if name == _dom.name
    return _dom 
  else if _dom.children.length > 0
    for child in _dom.children
      result = find_child_by_name(child, name)
      return result if result?

class Google
  
  search: (query, callback) ->
    google_api_client = http.createClient 80, 'ajax.googleapis.com'

    console.log "[google#search] looking for #{ query }"

    #-----------------
    options =
      method  : 'GET'
      path    : '/ajax/services/search/web?v=1.0&q=' + querystring.escape(query)
      extra   : 
        host: 'ajax.googleapis.com'

    request = google_api_client.request options.method, options.path, options.extra
    request.end()
    request.on 'response', (response) ->
      if typeof(callback) == 'function'
        data = ''

        response.on 'data', (chunk) ->
          data += chunk

        response.on 'end', () ->
          results = JSON.parse(data)['responseData']['results']
          results.forEach (x) ->
            x.titleNoFormatting = x
              .titleNoFormatting
              .replace /&#([^\s]*)/g, (m1, m2) -> 
                String.fromCharCode(m2)
              .replace /&(nbsp|amp|quot|lt|gt)/g, (m1, m2) ->
                { 'nbsp': ' ', 'amp': '&', 'quot': '"', 'lt': '<', 'gt': '>' }[m2]
            # try to coerce to ascii
            x.titleNoFormatting = new Buffer(x.titleNoFormatting, 'ascii').toString('ascii')
            x
          callback.call(this, results)

  # unofficial weather api
  weather: (query, callback) ->
    google_client = http.createClient 80, 'www.google.com'

    console.log "[google#weather] finding weather for " + query

    #-----------------
    options =
      method  : 'GET'
      path    : '/ig/api?weather=' + querystring.escape(query)

    # http://nodejs.org/docs/v0.3.1/api/http.html#http.ClientRequest  
    request = google_client.request options.method, options.path

    # NOTE: the request is not complete. This method only sends the header of
    # the request. One needs to call request.end() to finalize the request and
    # retrieve the response. (This sounds convoluted but it provides a chance
    # for the user to stream a body to the server with request.write().) 
    request.end()
    request.on 'response', (response) ->
      if typeof(callback) == 'function'
        data = ''

        response.on 'data', (chunk) ->
          data += chunk

        response.on 'end', () ->
          results =
            city: ''      
            condition: ''
            temp_f: ''
            temp_c: '' 
            humidity: ''

          try 
            domjs = new DomJS()
            domjs.parse data, (err, dom) ->
              forecast = find_child_by_name(dom, 'forecast_information')
              current  = find_child_by_name(dom, 'current_conditions')

              results  = 
                city:      find_child_by_name(forecast, 'city').attributes.data      
                condition: find_child_by_name(current, 'condition').attributes.data
                temp_f:    find_child_by_name(current, 'temp_f').attributes.data
                temp_c:    find_child_by_name(current, 'temp_c').attributes.data 
                humidity:  find_child_by_name(current, 'humidity').attributes.data
          
          console.log "ready with results for #{ results.city }"
          callback(results)

module.exports = Google




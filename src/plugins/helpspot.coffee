#  mess around with your helpspot installation
{_} = require 'underscore'
http = require 'http'
querystring = require 'querystring'

# parsing XML api, there seems to be a problem with json responses
DomJS = require('dom-js').DomJS
find_child_by_name = (_dom, name) ->
  if name == _dom.name
    return _dom 
  else if _dom.children && _dom.children.length > 0
    for child in _dom.children
      result = find_child_by_name(child, name)
      return result if result?

populate_from_xml = (data, obj, callback) ->
  domjs = new DomJS
  domjs.parse data, (err, dom) ->
    if err
      obj
    else
      _.keys(obj).forEach (key) ->
        element = find_child_by_name(dom, key)
        obj[key] = element.text() if element 
      callback(obj)

logger = ( d ) ->
  try
    console.log "#{d.message.created_at}: #{d.message.body}"

class HelpspotAPI
  constructor: (@config) ->

  get_request: (request_id, callback) ->
    api_client = http.createClient 80, @config.helpspot_hostname

    query = querystring.stringify 
      method: 'private.request.get'
      xRequest: request_id
      output: 'xml'
      username: @config.helpspot_username
      password: @config.helpspot_password

    options = 
      method: 'GET'
      path  : @config.helpspot_path + "/api/index.php?" + query

    request = api_client.request options.method, options.path, host: @config.helpspot_hostname
    request.end()
    request.on 'response', (response) ->
      data = ''

      response.on 'data', (chunk) ->
        data += chunk

      response.on 'end', () ->
        try
          domjs = new DomJS()
          results = 
            xRequest: null
            xPersonAssignedTo: null
            xStatus: null
            dtGMTOpened: null
            dtGMTClosed: null
          populate_from_xml(data, results, callback)
        catch e
          console.log "Failed to parse Helpspot API response: #{ e.message }"

# link directly to a support request. Link template is an env variable with $
# where the request ID should be.
class Helpspot
  constructor: () ->
    @room_id_matcher = /(^|[^a-zA-Z0-9])(\d{5})($|[^a-zA-Z0-9])/ # try to avoid matching git hashes, etc
    @room_link_template = process.env.helpspot_link_template
    @api = new HelpspotAPI
      helpspot_hostname: process.env.helpspot_hostname
      helpspot_path: process.env.helpspot_path
      helpspot_username: process.env.helpspot_username
      helpspot_password: process.env.helpspot_password

  link_to_ticket: (message, room) ->
    request_id = @room_id_matcher.exec(message)[2]
    @api.get_request request_id, (request) =>
      if request && request.xRequest == request_id
        link = @room_link_template.replace('$', request_id)
        room.speak "#{ link }", logger
  
  ticket_status: (message, room) ->
    request_id = @room_id_matcher.exec(message)[2]
    @api.get_request request_id, (request) =>
      if request && request.xRequest == request_id
        link = @room_link_template.replace('$', request_id)
        room.speak "#{ link } \n\nassigned to: #{ request.xPersonAssignedTo.split(' ')[0] },\nstatus: #{ request.xStatus },\nopened: #{ request.dtGMTOpened },\nclosed: #{ request.dtGMTClosed }", logger
      else
        room.speak "I couldn't find a ticket with id: #{ request_id }", logger

  listen: (msg, room, env) ->
    body = msg.body
    if @room_id_matcher.test(body)
      # message has a request...
      
      # status update?
      if /pat/i.test(body) && /status/i.test(body)
        console.log "getting helpspot status: #{ @room_id_matcher.exec(msg.body)[2] }"
        @ticket_status body, room
      else
        console.log "posting helpspot link: #{ @room_id_matcher.exec(msg.body)[2] }"
        @link_to_ticket body, room

module.exports = new Helpspot

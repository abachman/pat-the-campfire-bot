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

logger = ( d ) ->
  try
    console.log "#{d.message.created_at}: #{d.message.body}"

# { xRequest: '20000',
#   fOpenedVia: 'Email',
#   xOpenedViaId: 'Logged in staff member',
#   xPortal: '0',
#   xMailboxToSendFrom: '1',
#   xPersonOpenedBy: '',
#   xPersonAssignedTo: 'John Doe',
#   fOpen: '0',
#   xStatus: 'Responded',
#   fUrgent: '0',
#   xCategory: 'Our Product',
#   dtGMTOpened: 'Aug  3, 2010',
#   dtGMTClosed: 'Aug  3, 2010',
#   iLastReplyBy: 'John Doe',
#   fTrash: '0',
#   dtGMTTrashed: '',
#   sRequestPassword: 'aaaaaa',
#   sTitle: 'RE: Something I heard',
#   sUserId: '',
#   sFirstName: 'M.',
#   sLastName: 'Robotic',
#   sEmail: 'bolton@michael.net',
#   sPhone: '',
#   Custom1: '',
#   Custom2: '',
#   fullname: 'M. Robotic',
#   reportingTags: { tag: [ [Object], [Object] ] },
#   request_history: 
#    { item: 
#       { '70000': [Object],
#         '70001': [Object],
#         '70002': [Object],
#         '70003': [Object] } } }

class HelpspotAPI
  constructor: (@config) ->

  get_request: (request_id, callback) ->
    api_client = http.createClient 80, @config.helpspot_hostname

    query = querystring.stringify 
      method: 'private.request.get'
      xRequest: request_id
      output: 'json'
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
        console.log "GOT end EVENT ON HELPSPOT API!"
        try
          results = JSON.parse data
          callback results
        catch e
          console.log "Failed to parse Helpspot API response on end: #{ e.message }"

      response.on 'close', () ->
        console.log "GOT close EVENT ON HELPSPOT API!"
        try 
          results = JSON.parse data
          callback results
        catch e
          console.log "Failed to parse Helpspot API response on close: #{ e.message }"


# link directly to a support request. Link template is an env variable with $
# where the request ID should be.
class Helpspot
  name: "Helpspot"

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
    @api.get_request request_id, (results) =>
      console.log "I'm back with the results"
      console.dir results
      if results && results.xRequest == request_id
        console.log "speaking!"
        link = @room_link_template.replace('$', request_id)
        room.speak "#{ link }", logger
  
  ticket_status: (message, room) ->
    request_id = @room_id_matcher.exec(message)[2]
    @api.get_request request_id, (request) =>
      if request && request.xRequest == request_id
        link = @room_link_template.replace('$', request_id)
        out =  "#{ link } \n\n"
        out += "assigned to: #{ request.xPersonAssignedTo.split(' ')[0] } \n"
        out += "from:        #{ request.fullname } \n"
        out += "subject:     #{ request.sTitle } \n"
        out += "category:    #{ request.xCategory } \n"
        out += "status:      #{ request.xStatus } \n"
        out += "opened:      #{ request.dtGMTOpened } \n"
        if request.dtGMTClosed && request.dtGMTClosed.length
          out += "closed:      #{ request.dtGMTClosed } \n"
        room.paste out, logger
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

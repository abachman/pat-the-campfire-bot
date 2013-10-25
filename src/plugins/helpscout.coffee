#  mess around with your helpspot installation
{_} = require 'underscore'
https = require 'https'

# A Help Scout "item"
#{
#    "id": 2391938111,
#    "type": email,
#    "folder": "1234",
#    "isDraft": "false",
#    "number": 349,
#    "owner": {
#        "id": 1234,
#        "firstName": "Jack",
#        "lastName": "Sprout",
#        "email": "jack.sprout@gmail.com",
#        "phone": null,
#        "type": "user"
#    },
#    "mailbox": {
#        "id": 1234,
#        "name": "My Mailbox"
#    },
#    "customer": {
#        "id": 29418,
#        "firstName": "Vernon",
#        "lastName": "Bear",
#        "email": "vbear@mywork.com",
#        "phone": "800-555-1212",
#        "type": "customer"
#    },
#    "threadCount": 4,
#    "status": "active",
#    "subject": "I need help!",
#    "preview": "Hello, I tried to download the file off your site...",
#    "createdBy": {
#        "id": 29418,
#        "firstName": "Vernon",
#        "lastName": "Bear",
#        "email": "vbear@mywork.com",
#        "phone": null,
#        "type": "customer"
#    },
#    "createdAt": "2012-07-23T12:34:12Z",
#    "modifiedAt": "2012-07-24T20:18:33Z",
#    "closedAt": null,
#    "closedBy": null,
#    "source": {
#        "type": "email",
#        "via": "customer"
#    },
#    "cc": [
#        "cc1@somewhere.com",
#        "cc2@somewhere.com"
#    ],
#    "bcc": [
#        "bcc1@somewhere.com",
#        "bcc2@somewhere.com"
#    ],
#    "tags": [
#        "tag1",
#        "tag2"
#    ],
#    "threads": [{
#        "id": 88171881,
#        "assignedTo": {
#            "id": 1234,
#            "firstName": "Jack",
#            "lastName": "Sprout",
#            "email": "jack.sprout@gmail.com",
#            "phone": null,
#            "type": "user"
#        },
#        "status": "active",
#        "createdAt": "2012-07-23T12:34:12Z",
#        "createdBy": {
#            "id": 1234,
#            "firstName": "Jack",
#            "lastName": "Sprout",
#            "email": "jack.sprout@gmail.com",
#            "phone": null,
#            "type": "user"
#        },
#        "source": {
#            "type": "web",
#            "via": "user"
#        },
#        "type": "message",
#        "state": "published",
#        "customer": {
#            "id": 29418,
#            "firstName": "Vernon",
#            "lastName": "Bear",
#            "email": "vbear@mywork.com",
#            "phone": "800-555-1212",
#            "type": "customer"
#        },
#        "fromMailbox": null,
#        "body": "This is what I have to say. Thank you.",
#        "to": [
#            "customer@somewhere.com"
#        ],
#        "cc": [
#            "cc1@somewhere.com",
#            "cc2@somewhere.com"
#        ]
#        "bcc": [
#            "bcc1@somewhere.com",
#            "bcc2@somewhere.com"
#        ],
#        "attachments": [{
#            "id": 12391,
#            "mimeType": "image/jpeg",
#            "filename": "logo.jpg",
#            "size": 22,
#            "width": 160,
#            "height": 160,
#            "url": "https://secure.helpscout.net/some-url/logo.jpg"
#        }]
#    }],
#    "bcc": [
#        "bcc1@somewhere.com",
#        "bcc2@somewhere.com"
#    ],
#    "tags": [
#        "tag1",
#        "tag2",
#        "tag3"
#    ]
#}

class HelpScoutAPI
  hostname: "api.helpscout.net"

  constructor: (@config) ->

  get: (options, callback) ->
    # make the request
    request = https.request options, (response) ->
      data = ''

      response.on 'data', (chunk) ->
        data += chunk

      response.on 'end', () ->
        console.log "GOT end EVENT ON HelpScout API with #{ data.length } bytes of data"

        try
          results = JSON.parse data
          callback results
        catch e
          console.log "Failed to parse HelpScout API response on end: #{ e.message }"
          callback null

      response.on 'close', () ->
        console.log "GOT close EVENT ON HelpScout API!"
        try
          results = JSON.parse data
          callback results
        catch e
          console.log "Failed to parse HelpScout API response on close: #{ e.message }"
          callback null

    request.end()

    request.on 'error', (e) ->
      console.error(e)
      callback null


  get_conversation_by_number: (number, callback) ->
    options =
      host: @hostname
      port: 443
      path: "/v1/conversations/number/#{ number }.json"
      # auth
      headers:
        'Authorization': 'Basic ' + new Buffer("#{ @config.helpscout_api_key }:X").toString('base64')

    @get(options, callback)

class HelpScout
  name: "HelpScout"

  room_number_matcher: /(^|[^a-zA-Z0-9])[\/#](\d+)($|[^a-zA-Z0-9])/ # try to avoid matching git hashes, etc

  # link directly to a support request
  link_message: _.template("
    [<%= mailbox.name %>] <%= subject %> - <%= customer.email %>\n
    https://secure.helpscout.net/conversation/<%= id %>/<%= number %>/
    <% if (tags != null) { %>(<%= tags.join(', ') %>)<% } %>
  ".replace(/^\s+|\s+$/gm,''))

  constructor: () ->
    @api = new HelpScoutAPI(helpscout_api_key: process.env.helpscout_api_key)

  link_to_ticket: (message, room, logger) ->
    request_id = @room_number_matcher.exec(message)[2]
    @api.get_conversation_by_number request_id, (results) =>
      if results? and results.item?
        room.speak @link_message(results.item), logger

  listen: (msg, room, logger) ->
    body = msg.body

    if @room_number_matcher.test(body)
      # message has a request...
      console.log "posting helpscout link: #{ @room_number_matcher.exec(msg.body)[2] }"
      @link_to_ticket body, room, logger

module.exports = new HelpScout

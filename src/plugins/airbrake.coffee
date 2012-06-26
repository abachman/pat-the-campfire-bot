util       = require('util')
{curl, getClientIp} = require('../vendor/simple_http')
SpeakOnce  = require('../vendor/speak_once').SpeakOnce
{_}        = require('underscore')

module.exports =
  name: "Airbrake Webhook"

  http_listen: (request, response, logger) ->
    if /\/airbrake-webhook/i.test request.url
      clientIp = getClientIp request
      console.log "/airbrake-webhook got a #{request.method} message from #{ clientIp }"

      data = ""

      request.on 'data', (incoming) ->
        data += incoming

      request.on 'end', ->
        response.writeHead 200, {'Content-Type': 'text/html'}
        response.end "okay #{ clientIp }"

        imcoming = null
        try
          incoming = JSON.parse data
        catch e
          console.log "[airbrake] error parsing airbrake data, bailing. :("
          console.log "[airbrake] #{ e.message }"
          return false

        try
          # { error:
          #   { id: 51361566,
          #     error_message: 'RuntimeError: I\'ve made a huge mistake',
          #     error_class: 'RuntimeError',
          #     file: '/testapp/app/models/user.rb',
          #     line_number: 53,
          #     project: { id: 20411, name: 'tixatobeta' },
          #     last_notice:
          #      { id: 6283101553,
          #        request_method: null,
          #        request_url: 'http://example.com',
          #        backtrace: [] },
          #     environment: 'production',
          #     first_occurred_at: '2012-06-26T19:55:19Z',
          #     last_occurred_at: '2012-06-26T19:55:19Z',
          #     times_occurred: 1 } }
          console.log util.inspect(incoming)
          error = incoming.error
          error_message = "
            error message:    #{error.error_message}\n
            in file:          #{error.file}:#{error.line_number}\n
            request url:      #{error.last_notice.request_url}\n
            first occurrance: #{error.first_occurred_at}\n
            times occcurred:  #{error.times_occurred}\n\n

            http://airbrake.io/errors/#{error.id}\n
          "
          error_message = error_message.replace /^[ \t]+/gm, ''

          new SpeakOnce (room) ->
            if data.length > 0
              room.speak "[#{error.project.name}] Airbrake is reporting an error!"
              _.delay (-> room.paste error_message), 500

        catch e
          console.log "[airbrake] error converting JSON to error message, bailing :("
          console.log "[airbrake] #{e.message}"


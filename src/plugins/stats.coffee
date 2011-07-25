{_}   = require 'underscore'
store = require '../store'

Counter = store.Counter
User    = store.User
date_id = store.date_id

campfire_stats = (message, room) ->
  today = date_id()
  tdate = new Date

  console.log 'preparing campfire stats for today'

  message = "Campfire tally for #{ tdate.getFullYear() }-#{ tdate.getMonth() + 1 }-#{ tdate.getDate() }. "

  results = {}

  # total
  Counter.findOne {name: today}, (e, counter) -> 
    console.log "found today counter"

    if counter
      results.Total = counter.value
    else
      results.Total = 0
      return

    # then people
    User.find {}, [], (err, users) ->
      ticks = users.length

      users.forEach (user) ->
        uid = "#{ user.user_id }-#{ today }"
        # then counters
        Counter.findOne {name: uid}, (e, counter) ->
          if counter
            results[user.name] = counter.value
          else
            results[user.name] = 0
          ticks--
          if ticks == 0
            counters = _.keys results
            counters = _.sortBy counters, (c) -> results[c]
            list = _.map counters, (c) -> "#{ c }: #{ results[c] }"  
            message += list.join ', '

            room.speak message

module.exports = 
  listen: (message, room) ->
    if /pat/i.test(message.body) and /stats/i.test(message.body)
      console.log 'stats request?'

      if /(campfire|cf)/i.test(message.body)
        campfire_stats(message, room)


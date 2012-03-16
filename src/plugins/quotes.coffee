util = require('util')
curl = require('../vendor/simple_http').curl
qs   = require('querystring')
_    = require('underscore')._

# http://www.iheartquotes.com/api/v1/random?format=json&source=1811_dictionary_of_the_vulgar_tongue

quote_host = 'www.iheartquotes.com'
quote_port = 80

valid_sources = [
  'esr', 'humorix_misc', 'humorix_stories', 'joel_on_software', 'macintosh',
  'math', 'mav_flame', 'osp_rules', 'paul_graham', 'prog_style', 'subversion',
  '1811_dictionary_of_the_vulgar_tongue', 'codehappy', 'fortune', 'liberty',
  'literature', 'misc', 'oneliners', 'riddles', 'rkba', 'shlomif',
  'shlomif_fav', 'stephen_wright', 'calvin', 'forrestgump', 'friends',
  'futurama', 'holygrail', 'powerpuff', 'simon_garfunkel', 'simpsons_cbg',
  'simpsons_chalkboard', 'simpsons_homer', 'simpsons_ralph', 'south_park',
  'starwars', 'xfiles', 'contentions', 'osho', 'cryptonomicon',
  'discworld', 'dune', 'hitchhiker',
]

source_report = "
From geek: esr humorix_misc humorix_stories joel_on_software macintosh math mav_flame osp_rules paul_graham prog_style subversion\n
From general: 1811_dictionary_of_the_vulgar_tongue codehappy fortune liberty literature misc oneliners riddles rkba shlomif shlomif_fav stephen_wright\n
From pop: calvin forrestgump friends futurama holygrail powerpuff simon_garfunkel simpsons_cbg simpsons_chalkboard simpsons_homer simpsons_ralph south_park starwars xfiles\n
From scifi: cryptonomicon discworld dune hitchhiker\n\n
http://iheartquotes.com/api
"

module.exports =
  name: "Anagrammit"
  listen: (message, room, logger) ->
    body = message.body

    return unless body?

    if /^pat/i.test(body) && /quote/i.test(body)
      if /sources/i.test(body)
        # tell what pat knows and exit
        room.paste source_report, logger
        return

      # use the given source
      source = _.find(word for word in body.split(' '), (w) -> w in valid_sources)
      # or pick a random one
      source = valid_sources[ Math.floor(Math.random() * valid_sources.length) ] unless source?

      options =
        host: quote_host
        port: quote_port
        path: "/api/v1/random?format=json&source=#{source}"

      curl options, (data) ->
        console.log "results for #{ source } are ready! #{ data }"
        results = JSON.parse(data)
        if results? and results.quote?
          room.speak results.quote, logger
        else
          room.speak "whoops, looks like they don't have any quotes for that", logger

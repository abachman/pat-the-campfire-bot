{EventEmitter} = require 'events'
mongoose  = require 'mongoose'
util      = require 'util'
jasmine   = require 'jasmine-node'

{Counter} = require '../lib/store'

describe 'Counter', ->
  it 'should be updateable', -> 
    counter = new Counter
      name: "test-counter"
      value: 1
      last_updated_at: Date.now()

    counter.save (e, c) ->
      Counter.findOne {name: 'test-counter'}, (err, doc) ->
        throw err if err

        doc.value = doc.value + 1

        doc.save (err, doc) ->
          expect(doc.value).toEqual(2)

          doc.remove (e, d) ->
            jasmine.asyncSpecDone()

    jasmine.asyncSpecWait()




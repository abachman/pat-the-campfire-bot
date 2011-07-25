mongoose  = require 'mongoose'
util      = require 'util'
jasmine   = require 'jasmine-node'

{User} = require '../lib/store'

describe 'User', ->
  it 'should be saveable', ->
    user = new User
      user_id: 1
      name: "PAT"

    user.save (err, doc) ->
      expect(doc.name).toEqual('PAT')
      expect(doc.user_id).toEqual('1')

      doc.remove (err, doc) ->
        jasmine.asyncSpecDone()

    jasmine.asyncSpecWait()

  it 'should be retrievable', ->
    user = new User
      user_id: 1
      name: "PAT"

    user.save (err, _doc) ->
      user = User.findOne {user_id: 1}, (err, doc) ->
        expect(doc.name).toEqual('PAT')
        expect(doc.user_id).toEqual('1')

        doc.remove (err, doc) ->
          jasmine.asyncSpecDone()

    jasmine.asyncSpecWait()


"use strict"

request = require 'supertest'
assert = require 'assert'
app = require './../coffee/server.coffee'

before (done) -> app.once 'ready', done

module.exports = app

describe 'ntb.api', ->
  describe '/', ->
    it 'should fail with no api key', (done) ->
      request(app)
        .get('/')
        .expect(400, done)

    it 'should fail for invalid api key', (done) ->
      request(app)
        .get('/?api_key=fail')
        .expect(401, done)

    it 'should authenticate for valid api key', (done) ->
      request(app)
        .get('/?api_key=dnt')
        .expect(200, done)

  describe '/:collection', ->
    require './collection-spec.coffee'

  describe ':collection/:document', ->
    require './document-spec.coffee'


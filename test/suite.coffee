"use strict"

request = require 'supertest'
assert = require 'assert'
exports.app = app = require './../coffee/server.coffee'
exports.data = data = require('./util/data-gen.coffee')(100)

before (done) -> app.once 'ready', done
beforeEach (done) ->
  db = app.get 'db'
  db.collection('test').drop (err) ->
    throw err if err
    db.collection('test').insert data, (err) ->
      throw err if err
      done()

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


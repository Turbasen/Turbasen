"use strict"

request = require 'supertest'
assert  = require 'assert'
data    = require './util/data.coffee'

exports.app   = app = require './../coffee/server.coffee'

before (done) -> app.once 'ready', done
beforeEach (done) ->
  cache = app.get 'cache'
  redis = cache.redis
  mongo = cache.mongo

  redis.flushall()
  mongo.dropCollection 'turer'
  mongo.dropCollection 'steder'

  cnt = 2
  for type in data.getTypes()
    mongo.collection(type).insert data.get(type, true), {safe: true, w: 1}, (err, msg) ->
      assert.ifError(err)
      done() if --cnt is 0

describe 'Cache', ->
  require './cache-spec.coffee'

describe 'ntb.api', ->
  describe '/', ->
    it 'should fail with no api key', (done) ->
      request(app)
        .get('/')
        .expect(403)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.message, 'API key missing'
          done()

    it 'should fail for invalid api key', (done) ->
      request(app)
        .get('/?api_key=fail')
        .expect(401)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.message, 'API key invalid'
          done()

    it 'should authenticate for valid api key', (done) ->
      request(app)
        .get('/?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.message, 'Here be dragons'
          done()

  describe '/objekttyper', ->
    it 'should get avaiable object types', (done) ->
      request(app)
        .get('/objekttyper?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          assert.ifError(err)
          assert.deepEqual res.body, ['turer', 'steder', 'områder', 'grupper', 'aktiviteter', 'bilder']
          done()
  describe '/:system', ->
    require './system-spec.coffee'

  describe '/:collection', ->
    require './collection-spec.coffee'

  describe '/:collection/:document', ->
    require './document-spec.coffee'


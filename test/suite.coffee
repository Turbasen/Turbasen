"use strict"

ObjectID  = require('mongodb').ObjectID
request   = require 'supertest'
assert    = require 'assert'

mongo     = require './../coffee/db/mongo'
redis     = require './../coffee/db/redis'
app       = require './../coffee/server'

steder    = require './data/steder.json'

# For some reason NodeJS or Mocha caches the object array but still tries to run
# the Object to ObjectID convertion. This results in new ObjectIDs for every run
# > 0. new ObjectID(ObjectID) => new ObjectId()
#
if not (steder[0]._id instanceof ObjectID)
  steder[key]._id = new ObjectID(val._id['$oid']) for val, key in steder

exports.steder = JSON.parse(JSON.stringify(steder))

before (done) -> mongo.once 'ready', done
beforeEach (done) ->
  redis.flushall()
  mongo.db.dropCollection 'test'
  mongo.db.dropCollection 'steder'

  mongo.steder.ensureIndex geojson: '2dsphere', (err) ->
    assert.ifError(err)
    mongo.steder.insert steder, {safe: true, w: 1}, (err, msg) ->
      assert.ifError(err)
      done()

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

  describe '/notfound', ->
    it 'should return 404 Not Found for missing resources', (done) ->
      request(app)
        .get('/this/is/not/found?api_key=dnt').expect(404).end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.message, 'Resurs ikke funnet'
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


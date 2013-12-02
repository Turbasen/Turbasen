"use strict"

request = require 'supertest'
assert = require 'assert'

exports.app = app = require './../coffee/server.coffee'
exports.data = data = require('./util/data-gen.coffee')(100)
exports.mongo = mongo = null

# @TODO ok, so we had to hack this
data[50].status = "Offentlig"
data[51].status = "Offentlig"
data[52].status = "Offentlig"
data[53].status = "Offentlig"
data[53].status = "Offentlig"

exports.cache = redis = null

before (done) -> app.once 'ready', done
beforeEach (done) ->
  mongo = app.get 'db'
  cache = app.get 'cache'

  cache.flushall()
  mongo.collection('turer').drop (err) ->
    #throw err if err
    mongo.collection('turer').insert data, {safe: true}, (err) ->
      throw err if err
      done()

describe 'ntb.api', ->
  describe '/', ->
    it 'should fail with no api key', (done) ->
      request(app)
        .get('/')
        .expect(403)
        .end (err, res) ->
          throw err if err
          assert.equal res.body.message, 'API key missing'
          done()

    it 'should fail for invalid api key', (done) ->
      request(app)
        .get('/?api_key=fail')
        .expect(401)
        .end (err, res) ->
          throw err if err
          assert.equal res.body.message, 'API key invalid'
          done()

    it 'should authenticate for valid api key', (done) ->
      request(app)
        .get('/?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          throw err if err
          assert.equal res.body.message, 'Here be dragons'
          done()

  describe '/objekttyper', ->
    it 'should get avaiable object types', (done) ->
      request(app)
        .get('/objekttyper?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          throw err if err
          assert.deepEqual res.body, ['turer', 'steder', 'områder', 'grupper', 'aktiviteter', 'bilder']
          done()

  describe '/:collection', ->
    require './collection-spec.coffee'

  describe ':collection/:document', ->
    require './document-spec.coffee'


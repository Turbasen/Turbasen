"use strict"

request     = require 'supertest'
assert      = require 'assert'
data        = require './util/data'
cache       = require '../coffee/cache.coffee'

MongoClient = require('mongodb').MongoClient
ObjectID    = require('mongodb').ObjectID
Collection  = require('mongodb').Collection

redisify    = require('./util/fakeData.coffee').redisify

trip = poi = mongo = redis = null

before ->
  mongo = cache.mongo()
  redis = cache.redis()

beforeEach ->
  cache._setCols([])

  trip  = data.get('turer')
  poi   = data.get('steder')

  redis.flushall()

describe '#mongo()', ->
  it 'should get MongoDB instance', (done) ->
    assert cache.mongo() instanceof require('mongodb').Db
    done()

describe '#redis()', ->
  it 'should get Redis instance', (done) ->
    assert cache.redis() instanceof require('redis').RedisClient
    done()

describe '#hash()', ->
  it 'should hash simple objects', ->
    assert.equal cache.hash({foo: 'bar'}), '9bb58f26192e4ba00f01e2e7b136bbd8'

  it 'should add _id to data object if provided', ->
    assert.equal cache.hash({foo: 'bar'}, 'foo'), cache.hash({_id: 'foo', foo: 'bar'})

  it 'should hash complex objects', ->
    obj =
      string: '2012-10-15T01:57:11.005Z'
      number: 234521
      string_object: { foo: 'bar', bar: 'foo' }
      array_object: { foo: [1,2,3], bar: [4,5,6]}
      object_object: { foo: {foo: 'bar'}, bar: {foo: 'foo'} }
      string_array: ['foo', 'bar', 'baz']
      number_array: [1,2,3,4,5,6,7]
      object_array: [{ foo: 'bar', bar: 'foo'},{ foo: 'bar', bar: 'foo'}]
      array_array: [[1,2,3],[4,5,6]]

    assert.equal cache.hash(obj), 'ebe90952ea8c0dae5c0bd275e22dc315'

describe '#getFilter()', ->
  it 'should return default filter for certain data types', ->
    types = ['arrangement', 'grupper', 'områder', 'steder', 'turer']
    filter =
      _id       : false
      tilbyder  : true
      endret    : true
      status    : true
      navn      : true
      bilder    : true
      grupper   : true

    assert.deepEqual cache._getFilter(type), filter for type in types

  it 'should return special filter for bilder', ->
    filter =
      _id       : false
      tilbyder  : true
      endret    : true
      status    : true
      navn      : true

    assert.deepEqual cache._getFilter('bilder'), filter

  it 'should return default filter for unknown types', ->
    types = ['foo', 'bar', 'test', 'foobar', 'admin']
    filter =
      _id       : false
      tilbyder  : true
      endret    : true
      status    : true
      navn      : true
      bilder    : true
      grupper   : true

    assert.deepEqual cache._getFilter(type), filter for type in types

  it 'should return an empty object when told to prevent default', ->
    types = ['foo', 'bar', 'test', 'foobar', 'admin']
    assert.deepEqual cache._getFilter(type, true), {} for type in types

describe '#_filter()', ->
  it 'should filter data according to default data filters', ->
    assert.deepEqual cache._filter('turer', trip),
      tilbyder   : trip.tilbyder
      endret     : trip.endret
      status     : trip.status
      navn       : trip.navn
      bilder     : trip.bilder
      grupper    : trip.grupper

  it 'should filter data according to special data filters', ->
    assert.deepEqual cache._filter('bilder', trip),
      tilbyder   : trip.tilbyder
      endret     : trip.endret
      status     : trip.status
      navn       : trip.navn

describe '#col()', ->
  it 'should get new collections connection', ->
    assert cache.col('test') instanceof Collection

  it 'should save a reference to collection instance', ->
    assert.equal Object.keys(cache._getCols()).length, 0
    col = cache.col 'test'
    assert.equal Object.keys(cache._getCols()).length, 1
    assert cache._getCols()['test'] instanceof Collection

  it 'should retrive collection reference from cache', ->
    cache.col 'test'
    cache.col 'test'
    assert.equal Object.keys(cache._getCols()).length, 1

describe '#doc()', ->
  it 'should get existing document from database', (done) ->
    cache.doc 'turer', trip._id, (err, doc) ->
      assert.ifError(err)
      assert.deepEqual doc, cache._filter('turer', trip)
      done()

  it 'should handle nonexisiting documents', (done) ->
    cache.doc 'test', new ObjectID().toString(), (err, doc) ->
      assert.ifError(err)
      assert.equal doc, null
      done()

describe '#set()', ->
  it 'should set data for type and id', (done) ->
    doc = cache._filter('turer', trip)
    cache.set 'turer', trip._id, doc, (err, status) ->
      assert.ifError(err)
      redis.hgetall "turer:#{trip._id}", (err, d) ->
        assert.ifError(err)
        assert.equal d[key], val for key, val of redisify(doc)
        done()

describe '#get()', ->
  it 'should get document existing in redis cache', (done) ->
    doc = cache._filter('turer', trip)
    cache.set 'turer', trip._id, doc, (err) ->
      assert.ifError(err)
      cache.get 'turer', trip._id, (err, d, cacheHit) ->
        assert.ifError(err)
        assert.equal cacheHit, true
        assert.equal d[key], val for key, val of redisify(doc)
        done()

  it 'should get document from database when not in cahce', (done) ->
    cache.get 'turer', trip._id, (err, d, cacheHit) ->
      assert.ifError(err)
      assert.equal cacheHit, false
      for key, val of cache._filter('turer', trip)
        assert.deepEqual d[key], val if val instanceof Array
        assert.equal d[key], val if not val instanceof Array
      done()

  it 'should compute checksum for data not in cache', (done) ->
    cache.get 'turer', trip._id, (err, d, cacheHit) ->
      assert.ifError(err)
      assert.equal cacheHit, false
      checksum = d.checksum
      delete d.checksum
      assert.equal checksum, cache.hash(d, trip._id)
      done()

  it 'should return null data for cache miss for unknown data type', (done) ->
    cache.get 'test', new ObjectID(), (err, d, cacheHit) ->
      assert.ifError(err)
      assert.equal d, null
      assert.equal cacheHit, false
      done()

  it 'should cache missing document for known data types', (done) ->
    oid = new ObjectID().toString()
    cache.get 'turer', oid, (err, d1, cacheHit) ->
      assert.ifError(err)
      assert.equal d1.status, 'Slettet'
      assert.equal typeof d1.endret, 'string'
      assert.equal typeof d1.checksum, 'string'
      assert.equal cacheHit, false

      redis.hgetall "turer:#{oid}", (err, d2) ->
        assert.ifError(err)
        assert.equal d2.status, 'Slettet'
        assert.equal d2.endret, d1.endret
        assert.equal d2.checksum, d1.checksum

        cache.get 'turer', oid, (err, d3, cacheHit) ->
          assert.ifError(err)
          assert.equal d3.status, 'Slettet'
          assert.equal d3.endret, d1.endret
          assert.equal d3.checksum, d1.checksum
          assert.equal cacheHit, true

          done()


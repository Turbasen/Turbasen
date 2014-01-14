"use strict"

request     = require 'supertest'
assert      = require 'assert'
data        = require('./util/data')
Cache       = require '../coffee/Cache.class.coffee'

MongoClient = require('mongodb').MongoClient
ObjectID    = require('mongodb').ObjectID
Collection  = require('mongodb').Collection

redisify    = require('./util/fakeData.coffee').redisify

trip = poi = mongo = cache = null

before ->
  mongo = module.parent.exports.app.get('cache').mongo

beforeEach ->
  trip  = data.get('turer')
  poi   = data.get('steder')

  cache = new Cache mongo
  cache.redis.flushall()

describe 'new', ->
  it 'should instanciate new Cache instance', (done) ->
    assert cache instanceof Cache
    assert cache.mongo instanceof require('mongodb').Db
    assert cache.redis instanceof require('redis').RedisClient
    assert.deepEqual cache.cols, []
    done()

describe '#getFilter()', ->
  it 'should return default filter for certain data types', ->
    types = ['arrangement', 'grupper', 'områder', 'steder', 'turer']
    filter =
      _id       : false
      tilbyder  : true
      endret    : true
      checksum  : true
      status    : true
      navn      : true
      bilder    : true
      grupper   : true

    assert.deepEqual cache.getFilter(type), filter for type in types

  it 'should return special filter for bilder', ->
    filter =
      _id       : false
      tilbyder  : true
      endret    : true
      checksum  : true
      status    : true
      navn      : true

    assert.deepEqual cache.getFilter('bilder'), filter

  it 'should return default filter for unknown types', ->
    types = ['foo', 'bar', 'test', 'foobar', 'admin']
    filter =
      _id       : false
      tilbyder  : true
      endret    : true
      checksum  : true
      status    : true
      navn      : true
      bilder    : true
      grupper   : true

    assert.deepEqual cache.getFilter(type), filter for type in types

  it 'should return an empty object when told to prevent default', ->
    types = ['foo', 'bar', 'test', 'foobar', 'admin']
    assert.deepEqual cache.getFilter(type, true), {} for type in types

describe '#filterData()', ->
  it 'should filter data according to filter for type', ->
    doc = foo: 'foo', bar: {bar: 'bar'}, baz: [1, 2, 3]
    cache.dataFields.test = foo: true
    assert.deepEqual cache.filterData('test', doc), foo: doc.foo

  it 'should filter data according to predefined data filters', ->
    assert.deepEqual cache.filterData('turer', trip),
      tilbyder   : trip.tilbyder
      endret     : trip.endret
      checksum   : trip.checksum
      status     : trip.status
      navn       : trip.navn
      bilder     : trip.bilder
      grupper    : trip.grupper

describe '#getCol()', ->
  it 'should get new collections connection', ->
    assert cache.getCol('test') instanceof Collection

  it 'should save a reference to collection instance', ->
    assert.equal Object.keys(cache.cols).length, 0
    col = cache.getCol 'test'
    assert.equal Object.keys(cache.cols).length, 1
    assert cache.cols['test'] instanceof Collection

  it 'should retrive collection reference from cache', ->
    cache.getCol 'test'
    cache.getCol 'test'
    assert.equal Object.keys(cache.cols).length, 1

describe '#getDoc()', ->
  it 'should get existing document from database', (done) ->
    cache.getDoc 'turer', trip._id, (err, doc) ->
      assert.ifError(err)
      assert.deepEqual doc, cache.filterData('turer', trip)
      done()

  it 'should handle nonexisiting documents', (done) ->
    cache.getDoc 'test', new ObjectID().toString(), (err, doc) ->
      assert.ifError(err)
      assert.equal doc, null
      done()

describe '#set()', ->
  it 'should set data for type and id', (done) ->
    doc = cache.filterData('turer', trip)
    cache.set 'turer', trip._id, doc, (err, status) ->
      assert.ifError(err)
      cache.redis.hgetall "turer:#{trip._id}", (err, d) ->
        assert.ifError(err)
        assert.equal d[key], val for key, val of redisify(doc)
        done()

describe '#get()', ->
  it 'should get document existing in redis cache', (done) ->
    doc = cache.filterData('turer', trip)
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
      for key, val of cache.filterData('turer', trip)
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

      cache.redis.hgetall "turer:#{oid}", (err, d2) ->
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


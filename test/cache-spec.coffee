"use strict"

request     = require 'supertest'
assert      = require 'assert'
Cache       = require '../coffee/Cache.class.coffee'
util        = require './util.coffee'

ObjectID    = require('mongodb').ObjectID
Collection  = require('mongodb').Collection

mongo = cache = null

before ->
  mongo = module.parent.exports.app.get('cache').mongo

beforeEach ->
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
    doc = util.getDoc()
    assert.deepEqual cache.filterData('steder', doc),
      tilbyder  : doc.tilbyder
      endret    : doc.endret
      checksum  : doc.checksum
      status    : doc.status
      navn      : doc.navn
      bilder    : doc.bilder
      grupper   : doc.grupper

  it 'should handle undefined object properties', ->
    doc =
      status    : 'Slettet'
      endret    : new Date().toUTCString()
      checksum  : 'abc123'

    assert.deepEqual cache.filterData('steder', doc), doc

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
    doc = util.getDoc true
    cache.getCol('test').insert doc, (err, d) ->
      assert.ifError(err)
      cache.getDoc 'test', doc._id.toString(), (err, d) ->
        assert.ifError(err)
        assert.deepEqual d, cache.filterData 'test', doc
        done()

  it 'should handle nonexisiting documents', (done) ->
    cache.getDoc 'test', new ObjectID().toString(), (err, doc) ->
      assert.ifError(err)
      assert.equal doc, null
      done()

describe '#set()', ->
  it 'should set arbitrary key and data in redis', (done) ->
    doc = foo: 'bar', bar: 'foo'
    cache.set 'test', doc, (err, data) ->
      assert.ifError(err)
      cache.redis.hgetall 'test', (err, d) ->
        assert.ifError(err)
        assert.equal d[key], val for key, val of doc
        done()

describe '#get()', ->
  it 'should get data for arbitrary key existing in redis', (done) ->
    doc = foo: 'bar', bar: 'foo'
    cache.set 'foobar', doc, (err, data) ->
      assert.ifError(err)
      cache.get 'foobar', (err, d) ->
        assert.ifError(err)
        assert.equal d[key], val for key, val of doc
        done()

  it 'should fail gracefully for missing data in redis', (done) ->
    cache.get 'barfoo', (err, d) ->
      assert.ifError(err)
      assert.equal d, null
      done()

describe '#setForType()', ->
  it 'should set data for type and id', (done) ->
    orgDoc = util.getDoc()
    tmpDoc = cache.filterData 'test', orgDoc
    cache.setForType 'test', orgDoc._id, tmpDoc, (err, status) ->
      assert.ifError(err)
      cache.redis.hgetall "test:#{orgDoc._id}", (err, d) ->
        assert.ifError(err)
        assert.equal d[key], val for key, val of util.redisify(tmpDoc)
        done()

describe '#getForType()', ->
  it 'should get document existing in redis cache', (done) ->
    orgDoc = util.getDoc()
    tmpDoc = cache.filterData 'test', orgDoc
    cache.setForType 'test', orgDoc._id, tmpDoc, (err) ->
      assert.ifError(err)
      cache.getForType 'test', orgDoc._id, (err, d, cacheHit) ->
        assert.ifError(err)
        assert.equal cacheHit, true
        assert.equal d[key], val for key, val of util.redisify(tmpDoc)
        done()

  it 'should get document from database when not in cahce', (done) ->
    doc = util.getDoc true
    cache.getCol('test').insert doc, (err) ->
      assert.ifError(err)
      cache.getForType 'test', doc._id.toString(), (err, d, cacheHit) ->
        assert.ifError(err)
        assert.equal cacheHit, false
        for key, val of cache.filterData('test', doc)
          assert.deepEqual d[key], val if val instanceof Array
          assert.equal d[key], val if not val instanceof Array
        done()

  it 'should return slettet for data not in database', (done) ->
    cache.getForType 'test', new ObjectID().toString(), (err, d, cacheHit) ->
      assert.ifError(err)
      assert.deepEqual d, status: 'Slettet'
      assert.equal cacheHit, false
      done()

  it 'should cache missing document for known data types', (done) ->
    oid = new ObjectID().toString()
    cache.getForType 'test', oid, (err, d1, cacheHit) ->
      assert.ifError(err)
      assert.equal d1.status, 'Slettet'
      assert.equal typeof d1.endret, 'undefined'
      assert.equal typeof d1.checksum, 'undefined'
      assert.equal cacheHit, false

      cache.redis.hgetall "test:#{oid}", (err, d2) ->
        assert.ifError(err)
        assert.equal d2.status, 'Slettet'
        assert.equal d2.endret, d1.endret
        assert.equal d2.checksum, d1.checksum

        cache.getForType 'test', oid, (err, d3, cacheHit) ->
          assert.ifError(err)
          assert.equal d3.status, 'Slettet'
          assert.equal d3.endret, d1.endret
          assert.equal d3.checksum, d1.checksum
          assert.equal cacheHit, true

          done()


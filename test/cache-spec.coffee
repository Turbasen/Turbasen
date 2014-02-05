"use strict"

request     = require 'supertest'
assert      = require 'assert'
ObjectID    = require('mongodb').ObjectID
util        = require './util'

cache       = require '../coffee/cache'
redis       = require '../coffee/db/redis'
mongo       = require '../coffee/db/mongo'

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

describe '#getDoc()', ->
  it 'should get existing document from database', (done) ->
    doc = util.getDoc true
    mongo.steder.insert doc, (err, d) ->
      assert.ifError(err)
      cache.getDoc 'steder', doc._id.toString(), (err, d) ->
        assert.ifError(err)
        assert.deepEqual d, cache.filterData 'steder', doc
        done()

  it 'should handle nonexisiting documents', (done) ->
    cache.getDoc 'steder', new ObjectID().toString(), (err, doc) ->
      assert.ifError(err)
      assert.equal doc, null
      done()

describe '#set()', ->
  it 'should set arbitrary key and data in redis', (done) ->
    doc = foo: 'bar', bar: 'foo'
    cache.set 'steder', doc, (err, data) ->
      assert.ifError(err)
      redis.hgetall 'steder', (err, d) ->
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
    tmpDoc = cache.filterData 'steder', orgDoc
    cache.setForType 'steder', orgDoc._id, tmpDoc, (err, status) ->
      assert.ifError(err)
      redis.hgetall "steder:#{orgDoc._id}", (err, d) ->
        assert.ifError(err)
        assert.equal d[key], val for key, val of util.redisify(tmpDoc)
        done()

describe '#getForType()', ->
  it 'should get document existing in redis cache', (done) ->
    orgDoc = util.getDoc()
    tmpDoc = cache.filterData 'steder', orgDoc
    cache.setForType 'steder', orgDoc._id, tmpDoc, (err) ->
      assert.ifError(err)
      cache.getForType 'steder', orgDoc._id, (err, d, cacheHit) ->
        assert.ifError(err)
        assert.equal cacheHit, true
        assert.equal d[key], val for key, val of util.redisify(tmpDoc)
        done()

  it 'should get document from database when not in cahce', (done) ->
    doc = util.getDoc true
    mongo.steder.insert doc, (err) ->
      assert.ifError(err)
      cache.getForType 'steder', doc._id.toString(), (err, d, cacheHit) ->
        assert.ifError(err)
        assert.equal cacheHit, false
        for key, val of cache.filterData('steder', doc)
          assert.deepEqual d[key], val if val instanceof Array
          assert.equal d[key], val if not val instanceof Array
        done()

  it 'should return slettet for data not in database', (done) ->
    cache.getForType 'steder', new ObjectID().toString(), (err, d, cacheHit) ->
      assert.ifError(err)
      assert.deepEqual d, status: 'Slettet'
      assert.equal cacheHit, false
      done()

  it 'should cache missing document for known data types', (done) ->
    oid = new ObjectID().toString()
    cache.getForType 'steder', oid, (err, d1, cacheHit) ->
      assert.ifError(err)
      assert.equal d1.status, 'Slettet'
      assert.equal typeof d1.endret, 'undefined'
      assert.equal typeof d1.checksum, 'undefined'
      assert.equal cacheHit, false

      redis.hgetall "steder:#{oid}", (err, d2) ->
        assert.ifError(err)
        assert.equal d2.status, 'Slettet'
        assert.equal d2.endret, d1.endret
        assert.equal d2.checksum, d1.checksum

        cache.getForType 'steder', oid, (err, d3, cacheHit) ->
          assert.ifError(err)
          assert.equal d3.status, 'Slettet'
          assert.equal d3.endret, d1.endret
          assert.equal d3.checksum, d1.checksum
          assert.equal cacheHit, true

          done()


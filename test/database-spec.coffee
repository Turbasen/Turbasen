#
# Nasjonal Turbase v1
#
# Unit test for ./../coffee/database.coffee
#
# @author Hans Kristian Flaatten
#

"use strict"

assert = require 'assert'
Database = require './../coffee/database'

describe 'new Database()', ->
  ntb = null
  afterEach (done) ->
    return done() if ntb is null
    return ntb.close done

  it 'should return an Error if database connection fails', (done) ->
    ntb = new Database 'mongodb://undefined:1234/foo', (err, db) ->
      assert.notEqual err, null, 'err should not be null'
      assert err instanceof Error, 'err should be Error'
      assert.equal db, null
      done()

  it 'should return the database instance for successfull connection', (done) ->
    ntb = new Database 'mongodb://localhost:27017/ntb_test', (err, db) ->
      assert.equal err, null, 'err should be null'
      assert.notEqual db, null, 'db should not be null'
      assert.equal db.databaseName, 'ntb_test', 'database should be ntb_test'
      done()

  it 'should not suprepress runtime errors', (done) ->
    ntb = new Database 'mongodb://localhost:27017/ntb_test', (err, db) ->
      try
        foobar()
      catch e
        assert e instanceof Error, 'e should be an instance of error'
        assert /ReferenceError: foobar is not defined/.test(e), 'e should be ReferenceError'
        done()

describe '#open()', ->
  it 'should emit error if database connection fails', (done) ->
    ntb = new Database 'mongodb://undefined:1234/foo'
    ntb.once 'error', (err) ->
      assert.notEqual err, null, 'err should not be null'
      assert err instanceof Error, 'err should be Error'
      done()
    ntb.open()

  it 'should emit database instance in event mode', (done) ->
    ntb = new Database 'mongodb://localhost:27017/ntb_test'
    ntb.once 'error', (err) -> done err
    ntb.once 'ready', (db) ->
      assert.equal db.databaseName, 'ntb_test', 'database should be ntb_test'
      done()
    ntb.open()


describe '#getDatabase()', ->
  ntb = db = null
  before (done) ->
    ntb = new Database 'mongodb://localhost:27017/ntb_test', (err, db_ref) ->
      throw err if err
      db = db_ref
      done()

  after = (done) -> ntb.close done

  it 'should return connected database instance', (done) ->
    ntb_db = ntb.getDatabase()
    assert.equal db.databaseName, ntb_db.databaseName, 'database names should equal'
    done()

describe '#getCollection()', ->
  ntb = null
  before (done) ->
    ntb =  new Database 'mongodb://localhost:27017/ntb_test', (err, db) ->
      throw err if err
      done()

  after = (done) -> ntb.close done

  it 'should return collection instance without errors', (done) ->
    ntb.getCollection 'turer', (err, turer) ->
      throw err if err
      assert.notEqual turer, null, 'collection should not be null'
      done()

  it 'should cache collection instance internaly', (done) ->
    ntb.getCollection 'steder', (err, steder) ->
      throw err if err
      assert.notEqual steder, null, 'collection should not be null'
      assert.equal typeof ntb.cols.steder, 'object', 'collection should be cached'
      assert.equal typeof ntb.cols.turer, 'object', 'past collection is cached'
      done()

  it 'should reuse collection cache', (done) ->
    steder_old = ntb.cols.steder
    ntb.cols.steder = 'foobar'
    ntb.getCollection 'steder', (err, steder) ->
      throw err if err
      assert.equal steder, 'foobar', 'steder should equal fake cache'
      ntb.cols.steder = steder_old
      done()

describe '#_parseFields()', ->
  ntb = ntb = new Database 'mongodb://localhost:27017/ntb_test'

  it 'should return empty list if fields object is undefined', ->
    fields = ntb._parseFields undefined
    assert.deepEqual fields, {}, 'fields object should be empty'

  it 'should return empty list if fields object is null', ->
    fields = ntb._parseFields null
    assert.deepEqual fields, {}, 'fields object should be empty'

  it 'should return empty list if fields are not arrays', ->
    fields = ntb._parseFields include: 'foo', exclude: 'bar'
    assert.deepEqual fields, {}, 'fields object should be empty'

  it 'should return correct list of include fields', ->
    fields = ntb._parseFields include: ['foo', 'bar']
    
    assert fields.foo, 'foo filed should be included'
    assert fields.bar, 'bar field should be included'

  it 'should return currect list of excluded fields', ->
    fields = ntb._parseFields exclude: ['foo', 'bar']
    
    assert not fields.foo, 'foo filed should not be included'
    assert not fields.bar, 'bar field should not be included'
    
  it 'should return currect list of excluded and include fields', ->
    fields = ntb._parseFields include: ['foo', 'bar'], exclude: ['baz', 'zab']
    
    assert fields.foo, 'foo filed should be included'
    assert fields.bar, 'bar field should be included'
    
    assert not fields.baz, 'baz field should not be included'
    assert not fields.zab, 'zab field should not be included'

describe '#getDocuments()', ->
  ntb = col = null
  before (done) ->
    ntb = new Database process.env.MONGO_DEV_URI, (err, db) ->
      throw err if err
      ntb.getCollection 'turer', (err, turer) ->
        throw err if err
        col = turer
        done()

  after = (done) -> ntb.close done

  it 'should return documents for given collection', (done) ->
    ntb.getDocuments col, limit: 10, (err, docs) ->
      throw err if err

      assert.equal typeof docs, 'object', 'documents should be be an object'
      assert docs instanceof Array, 'documents should be an array'
      assert.equal docs.length, 10, 'document array length should be 10'
    
      done()

  it 'should set document projection fields correctly', (done) ->
    ntb.getDocuments col, {fields: {include: ['navn']}, limit: 10}, (err, docs) ->
      throw err if err

      assert.equal typeof docs, 'object', 'documents should be an object'
      assert docs instanceof Array, 'documents should be an array'

      for doc in docs
        assert.notEqual typeof doc._id, 'undefined', 'doc.id should be defined'
        assert.notEqual typeof doc.navn, 'undefined', 'doc.navn should be defined'

      done()

  it 'should handle limit correctly', (done) ->
    ntb.getDocuments col, {fields: {include: ['navn']}, limit: 5}, (err, docs) ->
      throw err if err

      assert.equal typeof docs, 'object', 'documents should be an object'
      assert docs instanceof Array, 'documents should be an array'
      assert.equal docs.length, 5, 'documents array should be 5 documents'

      done()

  it 'should handle offset correctly', (done) ->
    fields = include: ['navn']
    ntb.getDocuments col, {fields: fields, limit: 5}, (err, docs) ->
      throw err if err

      assert.equal docs.length, 5
      ntb.getDocuments col, {fields: fields, limit: 1, skip: 4}, (err, docs2) ->
        throw err if err
        assert.equal docs2.length, 1, 'number of documents returned should be 1'
        assert.equal docs[4]._id.toString(), docs2[0]._id.toString(), 'documents _ids shoudl be equal'
        done()

  it 'should handle sort correctly', (done) ->
    fields = include: ['navn', 'endret']
    ntb.getDocuments col, {fileds: fields, limit: 5, sort: 'endret'}, (err, docs) ->
      throw err if err
      for i in [1..4]
        assert docs[i].endret >= docs[i-1].endret, 'edited date should be gte from previous'
      done()

  it 'should handle query correctly', (done) ->
    query = endret: $gte: '2013-01-01'
    ntb.getDocuments col, {query: query, limit: 5}, (err, docs) ->
      throw err if err
      assert.equal docs.length, 5, 'number of documents returned should be 5'
      for doc in docs
        assert doc.endret > '2013-01-01', 'edit date should be gte 2013-01-01'
      done()

  it 'should handle empty collections', (done) ->
    ntb.getCollection 'does-not-exist', (err, collection) ->
      throw err if err
      ntb.getDocuments collection, {query: {endret: {$gte: '2013-01-01'}}}, (err, docs) ->
        throw err if err
        assert.equal docs.length, 0, 'number of documents returned should be 0'
        done()

describe '#getDocument', ->
  ntb = col = null
  before (done) ->
    ntb = new Database process.env.MONGO_DEV_URI, (err, db_ref) ->
      throw err if err
      ntb.getCollection 'turer', (err, turer) ->
        throw err if err
        col = turer
        done()

  after = (done) -> ntb.close done

  it.skip 'should get existing document', (done) ->
    ntb.getDocument col, "foobar", (err, doc) ->
      done()

describe.skip '#each()', ->
  db = col = null

  before (done) ->
    database.connect null, (err, database) ->
      throw err if err
      db = database
      db.collection 'turer', (err, collection) ->
        throw err if err
        col = collection
        done()

  after (done) -> db.close -> done()

  it 'should itterate over database cursor', (done) ->
    @timeout 10000

    cursor = col.find()
    counter = 0

    database.each cursor, (doc, i, count, cb) ->
      counter++
      cb()
    , (err, i, count) ->
      throw err if err
      assert.equal counter, count
      assert.equal i+1, count
      done()

  it 'should ittereate over database cursor with limit', (done) ->
    cursor  = col.find().limit(10)
    counter = 0

    database.each cursor, (doc, i, count, cb) ->
      counter++
      cb()
    , (err, i, count) ->
      throw err if err
      assert.equal counter, 10
      assert.equal i, 9
      assert.equal count, 10
      done()


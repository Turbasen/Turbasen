# Nasjonal Turbase v1
#
# Unit test for rest-api.coffee
#
# @author Hans Kristian Flaatten
#

"use strict"

assert   = require 'assert'
Database = require './../coffee/Database'
ObjectID = require('mongodb').ObjectID
api      = require './../coffee/rest-api'

describe '#apiKeyAuth()', ->
  describe 'URL param (?api_key=)', ->
    it 'should accept authentication for valid API key', (done) ->
      req =
        query:
          api_key: 'dnt'
  
      api.apiKeyVerify req, {}, (err) ->
        throw err if err
        assert.equal req.key.public, 'DNT'
        done()
  
    it 'should reject authentication for no API key', (done) ->
      req = {}

      api.apiKeyVerify req, {}, (err) ->
        assert.err instanceof Error
        assert.equal err.mesg, 'AuthenticationFailed'
        assert.equal err.code, 403
        assert.equal typeof req.key, 'undefined'
        done()

    it 'should reject authentication for invalid API key', (done) ->
      req =
        query:
          api_key: 'invalid'

      api.apiKeyVerify req, {}, (err) ->
        assert err instanceof Error
        assert.equal err.mesg, 'AuthenticationFailed'
        assert.equal err.code, 403
        assert.equal typeof req.key, 'undefined'
        done()

  describe 'HTTP header (api_key)', ->
    it 'should accept authentication for valid API key', (done) ->
      req =
        get: (key) ->
          return 'dnt' if key is 'api_key'
          return undefined
  
      api.apiKeyVerify req, {}, (err) ->
        throw err if err
        assert.equal req.key.public, 'DNT'
        done()
  
    it 'should reject authentication for no API key', (done) ->
      req =
        get: (key) ->
          return undefined

      api.apiKeyVerify req, {}, (err) ->
        assert.err instanceof Error
        assert.equal err.mesg, 'AuthenticationFailed'
        assert.equal err.code, 403
        assert.equal typeof req.key, 'undefined'
        done()

    it 'should reject authentication for invalid API key', (done) ->
      req =
        get: (key) ->
          return 'invalid'

      api.apiKeyVerify req, {}, (err) ->
        assert err instanceof Error
        assert.equal err.mesg, 'AuthenticationFailed'
        assert.equal err.code, 403
        assert.equal typeof req.key, 'undefined'
        done()

describe '#paramObject()', ->
  ntb = null
  before (done) ->
   ntb = new Database 'mongodb://localhost:27017/ntb_test', (err, db) ->
     throw err if err
     done()

  after (done) -> ntb.close done

  it 'should get existing collection', (done) ->
    req = {db: {con: ntb}}
    api.paramObject req, {}, (err) ->
      throw err if err
      assert.equal req.db.col.collectionName, 'turer'
      done()
    ,'turer'

  it 'should return error for system collections', (done) ->
    req = {db: {con: ntb}}
    api.paramObject req, {}, (err) ->
      assert err instanceof Error
      assert.equal typeof req.db.col, 'undefined'
      api.paramObject req, {}, (err) ->
        assert.err instanceof Error
        assert.equal typeof req.db.col, 'undefined'
        done()
      ,'system.foo'
    ,'system'
    
  it 'should return error for admin collections', (done) ->
    req = {db: {con: ntb}}
    api.paramObject req, {}, (err) ->
      assert err instanceof Error
      assert.equal typeof req.db.col, 'undefined'
      api.paramObject req, {}, (err) ->
        assert.err instanceof Error
        assert.equal typeof req.db.col, 'undefined'
        done()
      ,'admin.foo'
    ,'admin'

describe '#paramId()', ->
  it 'should accept 24 hex string', (done) ->
    req = {db: {}}
    api.paramId req, {}, (err) ->
      throw err if err
      assert.equal req.db.id, '507f191e810c19729de860ea'
      done()
    ,'507f191e810c19729de860ea'

  it 'should reject hex string less then 24 chars', (done) ->
    req = {db: {}}
    api.paramId req, {}, (err) ->
      assert err instanceof Error
      assert.equal err.mesg, 'ObjectIDMustBe24HexChars'
      assert.equal err.code, 400
      assert.equal typeof req.db.id, 'undefined'
      done()
    ,'507f191e810c19729'

  it 'should reject hex string longer then 24 chars', (done) ->
    req = {db: {}}
    api.paramId req, {}, (err) ->
      assert err instanceof Error
      assert.equal err.mesg, 'ObjectIDMustBe24HexChars'
      assert.equal err.code, 400
      assert.equal typeof req.db.id, 'undefined'
      done()
    ,'507f191e810c19729de860ea1cd'

  it 'should reject any non hex strings', (done) ->
    req = {db: {}}
    api.paramId req, {}, (err) ->
      assert err instanceof Error
      assert.equal err.mesg, 'ObjectIDMustBe24HexChars'
      assert.equal err.code, 400
      assert.equal typeof req.db.id, 'undefined'
      done()
    ,null

describe 'getObjectTypes()', ->
  it 'should get all avaiable data types', (done) ->
    api.getObjectTypes {},
      jsonp: (data) ->
        assert data.types instanceof Array, 'types should be an Array'
        assert.equal typeof data.count, 'number', 'count should be a number'
        assert.equal data.count, data.types.length, 'count should equal data.types.length'
        assert 'aktiviteter' in data.types, 'types should contain aktiviteter'
        assert 'bilder' in data.types, 'types should contain bilder'
        assert 'områder' in data.types, 'types should contain områder'
        assert 'steder' in data.types, 'types should contain steder'
        assert 'turer' in data.types, 'types should contain turer'
        done()

  it 'should not get any system nor admin collections', (done) ->
    api.getObjectTypes {},
      jsonp: (data) ->
        for type in data.types
          assert.notEqual type.substr(0,5), 'admin'
          assert.notEqual type.substr(0,6), 'system'
        done()

describe '#_parseOptions()', ->
  it 'should set limit properly', ->
    opts = api._parseOptions query: limit: 25
    assert.equal opts.limit, 25

  it 'should set max limit to 50', ->
    opts = api._parseOptions query: limit: 110
    assert.equal opts.limit, 50

  it 'should set offset properly', ->
    opts = api._parseOptions query: offset: 40
    assert.equal opts.skip, 40

  it 'should set after query properly', ->
    opts = api._parseOptions query: after: '2013-01-01'
    assert.equal opts.query.endret.$gt, '2013-01-01'

describe '#getObjectsByType()', ->
  ntb = col = last = null
  before (done) ->
    ntb = new Database 'mongodb://localhost:27017/ntb_test', (err, db) ->
      throw err if err
      ntb.getCollection 'turer', (err, collection) ->
        throw err if err
        col = collection
        done()
  after (done) -> ntb.close done

  fakeReq = (limit, offset, after) ->
    req =
      db    : con: ntb, col: col
      key   : public: 'DNT'
      query : {}
      params: object: col.collectionName

    req.query.limit  = limit if limit
    req.query.offset = offset if offset
    req.query.after  = after if after

    return req

  it 'should.getObjectsByType documents in given collection', (done) ->
    api.getObjectsByType fakeReq(),
      jsonp: (data) ->
        throw data if data instanceof Error

        assert.equal typeof data, 'object', 'data should be an object'
        assert data.documents instanceof Array, 'data.documents should be an array'
        assert.equal typeof data.count, 'number', 'data.count should be a number'
        assert.equal data.count, 10, 'number of documents should default to 10'
        assert.equal data.documents.length, data.count, 'data.documents.length should equal data.count'

        done()

  it 'should limit the number of items based on limit query param', (done) ->
    api.getObjectsByType fakeReq(5),
      jsonp: (data) ->
        throw data if data instanceof Error

        last = data.documents[4]

        assert.equal data.documents.length, 5, 'number of items returned should equal 5'
        assert.equal data.count, 5, 'count should limit (5)'

        done()

  it 'should skip n items based on offset query param', (done) ->
    api.getObjectsByType fakeReq(1,4),
      jsonp: (data) ->
        throw data if data instanceof Error

        assert.equal typeof data.documents[0], 'object', 'First element in array should be an object'
        assert.deepEqual data.documents[0], last, 'First and last last object should be the same'

        done()

  it 'should show items editited after a certain date', (done) ->
    api.getObjectsByType fakeReq(10,0,'2013-01-01'),
      jsonp: (data) ->
        throw data if data instanceof Error

        for document in data.documents
          assert document.endret > '2013-01-01', 'document should be edited after 2013-01-01'

        done()

  it.skip 'should alter document projection of object keys', (done) ->
    done()

  it.skip 'should sort documents based on sort query param', (done) ->
    done()

describe '#getObjectById()', ->
  ntb = col = null
  before (done) ->
    ntb = new Database 'mongodb://localhost:27017/ntb_test', (err, db) ->
      throw err if err
      ntb.getCollection 'turer', (err, collection) ->
        throw err if err
        col = collection
        done()
  after (done) -> ntb.close done

  fakeReq = (id, key) ->
    key = key or 'DNT'
    id  = ObjectID.createFromHexString id
    req =
      db    : con: ntb, col: col, id: id
      key   : public: key
      params: object: col.collectionName, id: id

    return req

  it 'should get document for existing ObjectID', (done) ->
    api.getObjectById fakeReq('51c7fccc57a4f9770f528793'),
      jsonp: (status, data) ->
        data = status if not data

        assert.equal typeof data, 'object', 'data should be an object'
        assert.equal data._id, '51c7fccc57a4f9770f528793', 'data._id should equal the request id'
        assert.equal typeof data.privat, 'object', 'private object property should show up'

        done()
    ,(err) ->
      throw err if err

  it 'should return error for nonexisting documents', (done) ->
    api.getObjectById fakeReq('52c7fccc57a4f9770f528793', 'DNT'),
      jsonp: (status, data) ->
        data = status if not data

        assert.equal status, 404
        assert.equal Object.keys(data).length, 0

        done()

  it 'should hide private object properties', (done) ->
    api.getObjectById fakeReq('51c7fccc57a4f9770f528793', 'NRK'),
      jsonp: (data, status) ->
        data = status if not data

        assert.equal typeof data, 'object', 'data should be an object'
        assert.equal data._id, '51c7fccc57a4f9770f528793', 'data._id should equal the request id'
        assert.equal typeof data.privat, 'undefined', 'private object property should be undefined'

        done()

describe.skip '#insert()', ->
  it 'should insert all the things'

describe.skip '#update()', ->
  it 'should update all the things'

describe.skip '#updates()', ->
  it 'should updates all the things'

describe.skip '#delete()', ->
  it 'should delete all the things'


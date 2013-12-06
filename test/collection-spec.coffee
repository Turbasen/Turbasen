"use strict"

ObjectID  = require('mongodb').ObjectID
request   = require 'supertest'
assert    = require 'assert'
data      = require('./util/data')
Generator = require('./util/fakeData').Generator

req = cache = trip = poi = null

before ->
  app = module.parent.exports.app
  req = request(app)
  cache = app.get 'cache'

beforeEach ->
  trip = data.get('turer')
  poi = data.get('steder')

describe 'OPTIONS', ->
  it 'should return allowed http methods', (done) ->
    req.options('/turer?api_key=dnt')
      .expect(200)
      .expect('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT', done)

describe 'GET', ->
  url = '/turer?api_key=dnt'

  it 'should get the collection', (done) ->
    req.get(url)
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 20
        assert.equal res.body.count, 20
        assert.equal res.body.total, 100
        done()

  it 'should grant access for the 6 known collections', (done) ->
    cols = ['turer', 'steder', 'områder', 'grupper', 'bilder', 'aktiviteter']
    count = cols.length

    for col in cols
      req.get(url.replace('turer', col))
        .expect(200)
        .end (err, res) ->
          assert.ifError(err)
          done() if --count is 0

  it 'should restrict access to unknown collections', (done) ->
    cols = ['system.test', 'test', 'admin', '_test', 'æøå']
    count = cols.length

    for col in cols
      req.get(url.replace('turer', col))
        .expect(404)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.message, 'Objekttype ikke funnet'
          done() if --count is 0

  it 'should return a limited set of document properties', (done) ->
    req.get(url)
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)

        for doc in res.body.documents
          assert.equal Object.keys(doc).length, 4
          assert.equal typeof doc._id, 'string'
          assert.equal typeof doc.endret, 'string'
          assert.equal typeof doc.status, 'string'
          assert.equal typeof doc.navn, 'string'

        done()

  it 'should handle improper formated parameters', (done) ->
    req.get(url + '&limit=foo&offset=bar')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 20
        done()

  it 'should limit number of items correctly', (done) ->
    req.get(url + '&limit=5')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 5
        done()

  it 'should limit limit to max 50', (done) ->
    req.get(url + '&limit=100')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 50
        done()

  it 'should offset items correctly', (done) ->
    req.get(url + '&limit=5')
      .expect(200)
      .end (err, res1) ->
        assert.ifError(err)

        req.get(url + '&limit=1&skip=4')
          .expect(200)
          .end (err, res2) ->
            assert.ifError(err)
            assert.deepEqual res1.body.documents[4], res2.body.documents[0]
            done()

  it 'should get items after specified date', (done) ->
    req.get(url + '&after=' + trip.endret)
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)

        for doc in res.body.documents
          assert doc.endret >= trip.endret

        done()

  it 'should parse milliseconds to ISO datestamp', (done) ->
    req.get(url + '&after=' + new Date(trip.endret).getTime())
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)

        for doc in res.body.documents
          assert doc.endret >= trip.endret

        done()

  it 'should handle invalid after parameter', (done) ->
    req.get(url + '&after=' + ['foo', 'bar'])
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal typeof res.body.message, 'undefined'
        done()

  it 'should handle empty after parameter', (done) ->
    req.get(url + '&after=')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 20
        done()

  it 'should list items with given tag in first position', (done) ->
    cache.getCol('turer').find({'tags.0': 'Sykkeltur'}).count (err, c) ->
      assert.ifError(err)
      req.get(url + '&tag=Sykkeltur')
        .expect(200)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.total, c
          done()

  it 'should list items with not given tag in first position', (done) ->
    cache.getCol('turer').find({'tags.0': {$ne: 'Sykkeltur'}}).count (err, c) ->
      assert.ifError(err)
      req.get(url + '&tag=!Sykkeltur')
        .expect(200)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.total, c
          done()

describe 'POST', ->
  gen = new Generator 'turer', exclude: ['_id', 'tilbyder', 'endret']
  url = '/turer?api_key=dnt'

  it 'should insert single object in collection and return ObjectID', (done) ->
    doc = gen.gen()
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.count, 1
      assert.equal typeof res.body.document, 'object'
      assert.equal typeof res.body.document._id, 'string'

      id = new ObjectID(res.body.document._id)
      cache.getCol('turer').findOne _id: id, (err, d) ->
        assert.ifError(err)
        assert.equal typeof d, 'object'
        assert.deepEqual d[key], val for key, val of doc
        done()

  it 'should override tilbyder and opprettet fields', (done) ->
    doc = gen.gen include: ['endret'], static: tilbyder: 'MINAPP'
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)

      id = new ObjectID(res.body.document._id)
      cache.getCol('turer').findOne _id: id, (err, d) ->
        assert.ifError(err)
        assert.notEqual d.tilbyder, doc.tilbyder
        assert.notEqual d.endret, doc.endret
        assert.deepEqual d[key], val for key, val of doc when key not in ['tilbyder', 'endret']
        done()

  it 'should handle rapid requests to collection', (done) ->
    this.timeout(5000)

    count = 100
    docs  = gen.gen(count)

    for doc in docs
      req.post(url).send(doc).expect(201).end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.count, 1
        assert.equal typeof res.body.document, 'object'
        done() if --count is 0

  it 'should convert _id to ObjectID if provided with one', (done) ->
    doc = gen.gen include: ['_id']
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.document._id, doc._id
      done()

  it 'should update existing document', (done) ->
    doc = JSON.parse(JSON.stringify(trip))
    doc.navn = 'Testtur'
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)

      cache.getCol('turer').findOne _id: new ObjectID(doc._id), (err, d) ->
        assert.ifError(err)
        assert.deepEqual d[key], val for key, val of doc when key not in ['_id', 'tilbyder', 'endret']
        done()

  it 'should add new documents to cache', (done) ->
    doc = gen.gen()
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      cache.get 'turer', res.body.document._id, (err, d) ->
        # @TODO undefined values
        assert.equal d[key], val for key,val of cache.filterData('turer', doc) when val
        done()

  it 'should warn about missing lisens field', (done) ->
    doc = new Generator('turer').gen exclude: ['lisens']
    req.post('/turer?api_key=dnt').send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert res.body.warnings, [{
        resource: 'turer'
        field: 'lisens'
        value: 'CC BY-ND-NC 3.0 NO'
        code: 'missing_field'
      }]
      done()

  it 'should warn about missing status field', (done) ->
    doc = new Generator('turer').gen exclude: ['status']
    req.post('/turer?api_key=dnt').send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert res.body.warnings, [{
        resource: 'turer'
        field: 'status'
        value: 'Kladd'
        code: 'missing_field'
      }]
      done()

  it 'should return error for missing request body', (done) ->
    req.post('/turer?api_key=dnt').expect(400, done)

  it 'should return error if request body is an array', (done) ->
    doc = new Generator('turer').gen()
    req.post('/turer?api_key=dnt').send([doc]).expect(422, done)

describe 'PUT', ->
  it 'should not be implemeted', (done) ->
    req.put('/turer?api_key=dnt')
      .expect(501, done)

describe 'PATCH', ->
  it 'should not be implemented', (done) ->
    req.patch('/turer?api_key=dnt')
      .expect(501, done)

describe 'DELETE', ->
  it 'should not be able to DELETE', (done) ->
    req.del('/turer?api_key=dnt')
      .expect(405, done)


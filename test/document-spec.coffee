"use strict"

request   = require 'supertest'
assert    = require 'assert'
data      = require('./util/data')
ObjectID  = require('mongodb').ObjectID

req = trip = poi = null

before ->
  app = module.parent.exports.app
  req = request(app)

beforeEach ->
  trip  = data.getTrip('DNT', 'Offentlig')
  poi   = data.get('steder')

url = (id, type) -> '/' + (type or 'turer') + '/' + id + '?api_key=dnt'

describe 'OPTIONS', ->
  it 'should return allowed http methods', (done) ->
    req.options(url(trip._id)).expect(200)
      .expect('Access-Control-Allow-Methods', 'HEAD, GET, PUT, PATCH, DELETE', done)

describe 'GET', ->
  it 'should reject invalid object id', (done) ->
    req.get(url('abc123')).expect(400, done)

  it 'should return 404 for not existing document', (done) ->
    req.get(url(new ObjectID().toString())).expect(404).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.error, 'Document Not Found'
      done()

  it 'should return 404 for status=Slettet', (done) ->
    doc = data.getTrip('DNT', 'Slettet')
    req.get(url(doc._id)).expect(404, done)

  it 'should return document when status=Offentlig and tilbyder=DNT', (done) ->
    req.get(url(trip._id)).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.deepEqual res.body, trip
      done()

  it 'should return document when status=Privat and tilbyder=DNT', (done) ->
    doc = data.getTrip('DNT', 'Privat')
    req.get(url(doc._id)).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.deepEqual res.body, doc
      done()

  it 'should return document when status=Offentlig and tilbyder=TURAPP', (done) ->
    doc = data.getTrip('TURAPP', 'Offentlig')
    delete doc.privat
    req.get(url(doc._id)).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.deepEqual res.body, doc
      done()

  it 'should return 404 for status=Privat and tilbyder TURAPP', (done) ->
    doc = data.getTrip('TURAPP', 'Privat')
    req.get(url(doc._id)).expect(404, done)

  it 'should set X-Cache-Hit header for cache hit', (done) ->
    req.get(url(trip._id)).expect(200).end (err, res) ->
      assert.ifError(err)
      req.get(url(trip._id)).expect(200).expect('X-Cache-Hit', 'true', done)

  it 'should set last modified header correctly', (done) ->
    time = new Date(trip.endret).toUTCString()
    req.get('/turer/' + trip._id + '?api_key=dnt')
      .expect(200)
      .expect('Last-Modified', time, done)

  it 'should set Etag header correctly', (done) ->
    req.get('/turer/' + trip._id + '?api_key=dnt')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal typeof res.header.etag, 'string'
        done()

  it 'should return 403 when provided with current valid Etag', (done) ->
    req.get('/turer/' + trip._id + '?api_key=dnt').expect(200).end (err, res) ->
      assert.ifError(err)
      req.get('/turer/' + trip._id + '?api_key=dnt')
        .set('if-none-match', res.header.etag)
        .expect(304, done)

  it 'should return documents without checksum', (done) ->
    doc = data.get 'turer', false, 37
    req.get("/turer/#{doc._id}?api_key=dnt").expect(200).end (err, res) ->
      assert.ifError(err)
      assert.deepEqual res.body, doc
      done()

  it 'should ignore etags for documents without checksum', (done) ->
    doc = data.get 'turer', false, 37
    req.get("/turer/#{doc._id}?api_key=dnt").set('if-none-match', 'foobar')
      .expect(200).end (err, res) ->
        assert.ifError(err)
        assert.deepEqual res.body, doc
        done()

  it 'should return newly created document (with id)', (done) ->
    doc = _id: new ObjectID().toString(), name: 'kristian'
    req.post('/turer?api_key=dnt').send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.document._id, doc._id
      req.get('/turer/' + doc._id + '?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.name, doc.name
          done()

  it 'should handle rapid fire', (done) ->
    this.timeout(5000)

    count = 0
    limit = data.get('turer', true).length
    for d in data.get('turer', true)
      req.get(url(d._id)).end (err, res) ->
        assert.ifError(err)
        done() if ++count is limit

describe 'HEAD', ->
  it 'should only get http header for document resource', (done) ->
    req.head(url(trip._id)).expect(200)
      .expect('X-Cache-Hit', /^(ture|false)$/)
      .expect('ETag', /^[0-9a-f]{32}$/)
      .expect('Last-Modified', /^[a-zA-Z0-9 ,:]+$/)
      .end (err, res) ->
        assert.ifError(err)
        assert.deepEqual(res.body, {})
        done()

describe 'POST', ->
  it 'should not be an allowed method', (done) ->
    req.post(url(trip._id)).expect 405, done

describe 'PUT', ->
  it 'should not be implmented', (done) ->
    req.put(url(trip._id)).expect 501, done

describe 'PATCH', ->
  it 'should not be implmented', (done) ->
    req.patch(url(trip._id)).expect 501, done

describe 'DELETE', ->
  it 'should not be implmented', (done) ->
    req.del(url(trip._id)).expect 501, done


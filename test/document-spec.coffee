"use strict"

ObjectID = require('mongodb').ObjectID
request = require 'supertest'
assert = require 'assert'

data = app = req = null

before ->
  data = module.parent.exports.data
  app = module.parent.exports.app
  req = request(app)

describe 'OPTIONS', ->
  it 'should return allowed http methods', (done) ->
    req.options('/turer/' + data[50]._id + '?api_key=dnt')
      .expect(200)
      .expect('Access-Control-Allow-Methods', 'GET, PUT, PATCH, DELETE', done)

describe 'GET', ->
  it 'should reject invalid object id', (done) ->
    req.get('/turer/123acb?api_key=dnt')
      .expect(400, done)

  it 'should return 404 for not existing document', (done) ->
    req.get('/turer/52580f8165de660317000001/?api_key=dnt')
      .expect(404)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.error, 'Document Not Found'
        done()

  it 'should return existing document', (done) ->
    src = JSON.parse(JSON.stringify(data[50]))
    src._id = src._id.toString()

    req.get('/turer/' + src._id + '?api_key=dnt')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.deepEqual res.body, src
        done()

  it 'should set cache header when using the cache', (done) ->
    url = '/turer/' + data[51]._id + '?api_key=dnt'
    req.get(url)
      .expect(200)
      .end (err, res) ->
        throw err if err
        req.get(url)
          .expect(200)
          .expect('X-Cache-Hit', 'true', done)

  it 'should set last modified header correctly', (done) ->
    time = new Date(data[51].endret).toUTCString()
    req.get('/turer/' + data[51]._id + '?api_key=dnt')
      .expect(200)
      .expect('Last-Modified', time, done)

  it 'should set Etag header correctly', (done) ->
    req.get('/turer/' + data[50]._id + '?api_key=dnt')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal typeof res.header.etag, 'string'
        done()

  it 'should return 403 when provided with current valid Etag', (done) ->
    req.get('/turer/' + data[50]._id + '?api_key=dnt')
      .expect(200)
      .end (err, res) ->
        throw err if err
        req.get('/turer/' + data[50]._id + '?api_key=dnt')
          .set('if-none-match', res.header.etag)
          .expect(304, done)

  it 'should return newly created document (with id)', (done) ->
    doc = _id: new ObjectID().toString(), name: 'kristian'
    req.post('/turer?api_key=dnt').send(doc).expect(201).end (err, res) ->
      throw err if err
      assert.equal res.body.document._id, doc._id
      req.get('/turer/' + doc._id + '?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          throw err if err
          assert.equal res.body.name, doc.name
          done()

  it 'should handle rapid fire', (done) ->
    this.timeout(5000)

    count = 0
    for d in data
      request(app).get('/turer/' + d._id + '?api_key=dnt')
        .end (err, res) ->
          throw err if err
          done() if ++count is data.length

describe 'POST', ->
  it 'should not be an allowed method', (done) ->
    req.post('/turer/' + data[50]._id + '?api_key=dnt')
      .expect 405, done

describe 'PUT', ->
  it 'should not be implmented', (done) ->
    req.put('/turer/' + data[50]._id + '?api_key=dnt')
      .expect 501, done

describe 'PATCH', ->
  it 'should not be implmented', (done) ->
    req.patch('/turer/' + data[50]._id + '?api_key=dnt')
      .expect 501, done

describe 'DELETE', ->
  it 'should not be implmented', (done) ->
    req.del('/turer/' + data[50]._id + '?api_key=dnt')
      .expect 501, done


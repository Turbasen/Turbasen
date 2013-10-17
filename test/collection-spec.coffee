"use strict"

request = require 'supertest'
assert = require 'assert'

data = app = req = null

before ->
  data = module.parent.exports.data
  app = module.parent.exports.app
  req = request(app)

describe 'OPTIONS', ->
  it 'should return allowed http methods', (done) ->
    req.options('/test?api_key=dnt')
      .expect(200)
      .expect('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT', done)

describe 'GET', ->
  url = '/test?api_key=dnt'

  it 'should get the collection', (done) ->
    req.get(url)
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 20
        done()

  it 'should handle improper formated parameters', (done) ->
    req.get(url + '&limit=foo&offset=bar')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 20
        done()

  it 'should limit number of items correctly', (done) ->
    req.get(url + '&limit=5')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 5
        done()

  it 'should offset items correctly', (done) ->
    req.get(url + '&limit=5')
      .expect(200)
      .end (err, res1) ->
        throw err if err

        req.get(url + '&limit=1&skip=4')
          .expect(200)
          .end (err, res2) ->
            throw err if err
            assert.deepEqual res1.body.documents[4], res2.body.documents[0]
            done()

describe 'POST', ->
  it 'should insert single object in collection and return ObjectID', (done) ->
    doc = name: 'tobi'
    req.post('/test?api_key=dnt').send(doc)
      .expect(201)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 1
        assert.equal res.body.count, 1
        assert.equal typeof res.body.documents[0], 'string'
        done()

  it 'should insert multiple objects in collection and return ObjectIDs', (done) ->
    docs = [
      {name: 'foo'}
      {name: 'bar'}
    ]
    req.post('/test?api_key=dnt').send(docs)
      .expect(201)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 2
        assert.equal res.body.count, 2
        assert.equal typeof res.body.documents[0], 'string'
        assert.equal typeof res.body.documents[1], 'string'
        done()

  it 'should handle rapid requests to collection', (done) ->
    count = 0
    target = 200
    for i in [1..target]
      req.post('/test?api_key=dnt').send({num:i}).expect(201).end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 1
        assert.equal res.body.count, 1
        assert.equal typeof res.body.documents[0], 'string'
        done() if ++count is target

  it 'should return error for missing request body', (done) ->
    req.post('/test?api_key=dnt')
      .expect(400, done)

describe 'PUT', ->
  it 'should not be implemeted', (done) ->
    req.put('/test?api_key=dnt')
      .expect(501, done)

describe 'PATCH', ->
  it 'should not be implemented', (done) ->
    req.patch('/test?api_key=dnt')
      .expect(501, done)

describe 'DELETE', ->
  it 'should not be able to DELETE', (done) ->
    req.del('/test?api_key=dnt')
      .expect(405, done)


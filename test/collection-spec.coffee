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
    req.options('/turer?api_key=dnt')
      .expect(200)
      .expect('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT', done)

describe 'GET', ->
  url = '/turer?api_key=dnt'

  it 'should get the collection', (done) ->
    req.get(url)
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 20
        assert.equal res.body.count, 20
        assert.equal res.body.total, 100
        done()

  it 'should return a limited set of document properties', (done) ->
    req.get(url)
      .expect(200)
      .end (err, res) ->
        throw err if err

        for doc in res.body.documents
          assert.equal Object.keys(doc).length, 3
          assert.equal typeof doc._id, 'string'
          assert.equal typeof doc.navn, 'string'
          assert.equal typeof doc.endret, 'string'

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

  it 'should limit limit to max 50', (done) ->
    req.get(url + '&limit=100')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 50
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

  it 'should get items after specified date', (done) ->
    req.get(url + '&after=' + data[50].endret)
      .expect(200)
      .end (err, res) ->
        throw err if err

        for doc in res.body.documents
          assert doc.endret >= data[50].endret

        done()

  it 'should parse milliseconds to ISO datestamp', (done) ->
    req.get(url + '&after=' + new Date(data[50].endret).getTime())
      .expect(200)
      .end (err, res) ->
        throw err if err

        for doc in res.body.documents
          assert doc.endret >= data[50].endret

        done()

  it 'should handle invalid after parameter', (done) ->
    req.get(url + '&after=' + ['foo', 'bar'])
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal typeof res.body.message, 'undefined'
        done()

  it 'should handle empty after parameter', (done) ->
    req.get(url + '&after=')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 20
        done()

  it 'should list items with given tag in first position', (done) ->
    count = 0
    req.get(url + '&tag=Hytte')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 20
        for doc in res.body.documents
          do (doc) ->
            req.get('/turer/' + doc._id + '?api_key=dnt')
              .expect(200)
              .end (err, r) ->
                throw err if err
                assert.equal r.body.tags[0], 'Hytte'
                done() if ++count is res.body.documents.length

  it 'should list items with not given tag in first position', (done) ->
    count = 0
    req.get(url + '&tag=!Hytte')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 20
        for doc in res.body.documents
          do (doc) ->
            req.get('/turer/' + doc._id + '?api_key=dnt')
              .expect(200)
              .end (err, r) ->
                throw err if err
                assert.equal r.body.tags[0], 'Sted'
                done() if ++count is res.body.documents.length

describe 'POST', ->
  it 'should insert single object in collection and return ObjectID', (done) ->
    doc = name: 'tobi'
    req.post('/turer?api_key=dnt').send(doc)
      .expect(201)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 1
        assert.equal res.body.count, 1
        assert.equal typeof res.body.documents[0], 'string'

        req.get('/turer?api_key=dnt')
          .expect(200)
          .end (err, res) ->
            throw err if err
            assert.equal res.body.total, 101, 'there should be total of 101 documents in collection'
            done()

  it 'should insert multiple objects in collection and return ObjectIDs', (done) ->
    docs = [
      {name: 'foo'}
      {name: 'bar'}
    ]
    req.post('/turer?api_key=dnt').send(docs)
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
      req.post('/turer?api_key=dnt').send({num:i}).expect(201).end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 1
        assert.equal res.body.count, 1
        assert.equal typeof res.body.documents[0], 'string'
        done() if ++count is target

  it 'should convert _id to ObjectID if provided with one', (done) ->
    doc = _id: new ObjectID().toString(), name: 'tuut-tuut'
    req.post('/turer?api_key=dnt').send(doc).expect(201).end (err, res) ->
      throw err if err
      assert.equal res.body.documents[0], doc._id
      done()

  it 'should update existing document', (done) ->
    doc = {_id: data[50]._id, navn: 'foo'}
    req.post('/turer?api_key=dnt').send(doc).expect(201).end (err, res) ->
      throw err if err
      assert.equal res.body.documents[0], doc._id
      done()

  it 'should return error for missing request body', (done) ->
    req.post('/turer?api_key=dnt')
      .expect(400, done)

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


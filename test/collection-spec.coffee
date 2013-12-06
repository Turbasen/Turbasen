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
    req.get(url + '&after=' + data[50].endret)
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)

        for doc in res.body.documents
          assert doc.endret >= data[50].endret

        done()

  it 'should parse milliseconds to ISO datestamp', (done) ->
    req.get(url + '&after=' + new Date(data[50].endret).getTime())
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)

        for doc in res.body.documents
          assert doc.endret >= data[50].endret

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
        for doc in res.body.documents when doc.status isnt 'Slettet'
          count++
          do (doc) ->
            req.get('/turer/' + doc._id + '?api_key=dnt')
              .expect(200)
              .end (err, r) ->
                throw err if err
                assert.equal r.body.tags[0], 'Hytte'
                done() if --count is 0

  it 'should list items with not given tag in first position', (done) ->
    count = 0
    req.get(url + '&tag=!Hytte')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.documents.length, 20
        for doc in res.body.documents when doc.status isnt 'Slettet'
          count++
          do (doc) ->
            req.get('/turer/' + doc._id + '?api_key=dnt')
              .expect(200)
              .end (err, r) ->
                throw err if err
                assert.equal r.body.tags[0], 'Sted'
                done() if --count is 0

describe 'POST', ->
  it 'should insert single object in collection and return ObjectID', (done) ->
    doc = name: 'Tur til Bergen', lisens: 'CC BY-NC 3.0 NO', status: 'Offentlig'
    req.post('/turer?api_key=dnt').send(doc)
      .expect(201)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.count, 1
        assert.equal typeof res.body.document, 'object'

        req.get('/turer?api_key=dnt')
          .expect(200)
          .end (err, res) ->
            throw err if err
            assert.equal res.body.total, 101, 'there should be total of 101 documents in collection'
            done()

  it 'should handle rapid requests to collection', (done) ->
    this.timeout(5000)

    count = 0
    target = 200
    for i in [1..target]
      req.post('/turer?api_key=dnt').send({num:i}).expect(201).end (err, res) ->
        throw err if err
        assert.equal res.body.count, 1
        assert.equal typeof res.body.document, 'object'
        done() if ++count is target

  it 'should convert _id to ObjectID if provided with one', (done) ->
    doc = _id: new ObjectID().toString(), name: 'tuut-tuut'
    req.post('/turer?api_key=dnt').send(doc).expect(201).end (err, res) ->
      throw err if err
      assert.equal res.body.document._id, doc._id
      done()

  it 'should update existing document', (done) ->
    doc = {_id: data[50]._id, navn: 'foo'}
    req.post('/turer?api_key=dnt').send(doc).expect(201).end (err, res) ->
      throw err if err
      assert.equal res.body.document._id, doc._id
      done()

  it 'should precache new documents', (done) ->
    req.post('/turer?api_key=dnt').send({ navn: 'foo' })
      .expect(201)
      .end (err, res) ->
        throw err if err
        req.get('/turer/' + res.body.document._id + '?api_key=dnt')
          .expect(200)
          .expect('X-Cache-Hit', 'true', done)

  it 'should warn about missing fields', (done) ->
    req.post('/turer?api_key=dnt').send({ navn: 'foo' })
      .expect(201)
      .end (err, res) ->
        throw err if err
        assert res.body.warnings, [
          {
            resource: 'turer'
            field: 'lisens'
            value: 'CC BY-ND-NC 3.0 NO'
            code: 'missing_field'
          }, {
            resource: 'turer'
            field: 'status'
            value: 'Kladd'
            code: 'missing_field'
          }
        ]
        done()

  it 'should return error for missing request body', (done) ->
    req.post('/turer?api_key=dnt').expect(400, done)

  it 'should return error if request body is an array', (done) ->
    req.post('/turer?api_key=dnt').send([{navn: 'foo'}]).expect(422, done)

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


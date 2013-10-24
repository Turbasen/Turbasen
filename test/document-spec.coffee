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
    req.options('/test/52580f8165de660317000001?api_key=dnt')
      .expect(200)
      .expect('Access-Control-Allow-Methods', 'GET, PUT, PATCH, DELETE', done)

describe 'GET', ->
  it 'should reject invalid object id', (done) ->
    req.get('/test/123acb?api_key=dnt')
      .expect(400, done)

  it 'should return 404 for not existing document', (done) ->
    req.get('/test/52580f8165de660317000001/?api_key=dnt')
      .expect(404)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.error, 'Document Not Found'
        done()

  it 'should return existing document', (done) ->
    src = JSON.parse(JSON.stringify(data[50]))
    src._id = src._id.toString()

    req.get('/test/' + src._id + '?api_key=dnt')
      .expect(200)
      .end (err, res) ->
        throw err if err
        assert.deepEqual res.body, src
        done()

  it 'should set last modified header correctly', (done) ->
    time = new Date(data[50].endret).getTime().toString()
    req.get('/test/' + data[50]._id + '?api_key=dnt')
      .expect(200)
      .expect('Last-Modified', time, done)

  it 'should return existing document (with id)', (done) ->
    doc = _id: new ObjectID().toString(), name: 'kristian'
    req.post('/test?api_key=dnt').send(doc).expect(201).end (err, res) ->
      throw err if err
      assert.equal res.body.documents[0], doc._id
      req.get('/test/' + doc._id + '?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          throw err if err
          assert.equal res.body.name, doc.name
          done()

describe 'POST', ->
  it 'should not be an allowed method', (done) ->
    req.post('/test/52580f8165de660317000001?api_key=dnt')
      .expect 405, done

describe 'PUT', ->
  it 'should not be implmented', (done) ->
    req.put('/test/52580f8165de660317000001?api_key=dnt')
      .expect 501, done

describe 'PATCH', ->
  it 'should not be implmented', (done) ->
    req.patch('/test/52580f8165de660317000001?api_key=dnt')
      .expect 501, done

describe 'DELETE', ->
  it 'should not be implmented', (done) ->
    req.del('/test/52580f8165de660317000001?api_key=dnt')
      .expect 501, done


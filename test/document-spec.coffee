"use strict"

request = require 'supertest'
assert = require 'assert'

app = req = null

before ->
  app = module.parent.exports
  req = request(app)

describe 'OPTIONS', ->
  it 'should return allowed http methods', (done) ->
    req.options('/turer/52580f8165de660317000001?api_key=dnt')
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
    doc = name: 'hans'
    req.post('/turer?api_key=dnt').send(doc).end (err, res) ->
      throw err if err
      assert.equal typeof res.body.documents[0], 'string'
      req.get('/turer/' + res.body.documents[0] + '?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          throw err if err
          assert.equal res.body.name, doc.name
          done()

describe 'POST', ->
  it 'should not be an allowed method', (done) ->
    req.post('/turer/52580f8165de660317000001?api_key=dnt')
      .expect 405, done

describe 'PUT', ->
  it 'should not be implmented', (done) ->
    req.put('/turer/52580f8165de660317000001?api_key=dnt')
      .expect 501, done

describe 'PATCH', ->
  it 'should not be implmented', (done) ->
    req.patch('/turer/52580f8165de660317000001?api_key=dnt')
      .expect 501, done

describe 'DELETE', ->
  it 'should not be implmented', (done) ->
    req.del('/turer/52580f8165de660317000001?api_key=dnt')
      .expect 501, done


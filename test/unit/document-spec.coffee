"use strict"

ObjectID  = require('mongodb').ObjectID
assert    = require 'assert'

mongo     = require '../../coffee/db/mongo'
redis     = require '../../coffee/db/redis'

document  = require '../../coffee/document'
Document  = require '../../coffee/model/Document'

req = {}
res = {}
spy = false

beforeEach (done) ->
  spy = false
  res =
    status: -> assert false, 'res.status called'
    json: -> assert false, 'res.json called'
    end: -> assert false, 'res.end called'
    headers: {}
    set: (header, value) ->
      @headers[header] = value
      @

  req =
    method: 'GET'
    headers: {}
    get: (header) -> @headers[header]
    usr: 'DNT'
    type: 'steder'
    isOwner: true

  req.doc = new Document(req.type, '52407fb375049e5615000008')
    .once('error', assert.fail)
    .once('ready', done)

describe '#param()', ->
  beforeEach ->
    delete req.doc
    delete req.isOwner

  it 'should return 400 error for invalid ObjectId', (done) ->
    res.json = (code, body) ->
      assert.equal code, 400
      assert.deepEqual body, message: 'Invalid ObjectId'
      done()

    document.param req, res, assert.false, 'foobar'

  it 'should return early if request method is OPTIONS', (done) ->
    req.method = 'OPTIONS'
    next = (err) ->
      assert.ifError err
      done()

    document.param req, res, next, '53b86e20970e053231a591aa'

  it 'should set document object to request', (done) ->
    delete req.doc
    next = (err) ->
      assert.ifError err
      assert req.doc instanceof Document, 'req.doc isnt Document'
      done()

    document.param req, res, next, '52407fb375049e5615000008'

  it 'should set isOwner to true if current user is owner', (done) ->
    delete req.isOwner
    next = (err) ->
      assert.ifError err
      assert.equal req.isOwner, true
      done()

    document.param req, res, next, '52407fb375049e5615000008'

  it 'should set isOwner to false if current user isnt owner', (done) ->
    delete req.isOwner
    req.usr = 'OTHER'
    next = (err) ->
      assert.ifError err
      assert.equal req.isOwner, false
      done()

    document.param req, res, next, '52407fb375049e5615000008'

  it 'should return 404 if document does not exist', (done) ->
    res.status = (code) -> assert.equal code, 404; @
    res.json = (body) ->
      assert.deepEqual body, message: 'Not Found'
      done()

    document.param req, res, assert.fail, '53b86e20970e053231a591aa'

  it 'should return 404 if document is not accessible for user', (done) ->
    req.usr = 'OTHER'
    res.status = (code) -> assert.equal code, 404; @
    res.json = (body) ->
      assert.equal req.doc.exists(), true
      assert.deepEqual body, message: 'Not Found'
      done()

    document.param req, res, assert.fail, '52d65b2544db971c94b2d949'

  it 'should return 404 with no body for HEAD requests', (done) ->
    req.method = 'HEAD'
    res.status = (code) -> assert.equal code, 404; @
    res.end = done

    document.param req, res, assert.fail, '53b86e20970e053231a591aa'

describe '#all()', ->
  it 'should set X-Cache-Hit header to false for doc cache miss', (done) ->
    req.doc.chit = false

    document.all req, res, (err) ->
      assert.ifError err
      assert.equal res.headers['X-Cache-Hit'], false
      done()

  it 'should set X-Cache-Hit header to true for doc cache hit', (done) ->
    req.doc.chit = true

    document.all req, res, (err) ->
      assert.ifError err
      assert.equal res.headers['X-Cache-Hit'], true
      done()

  it 'should set ETag header to doc checksum', (done) ->
    req.doc.data.checksum = 'foobar'

    document.all req, res, (err) ->
      assert.ifError err
      assert.equal res.headers['ETag'], '"foobar"'
      done()

  it 'should set Last-Modified header to doc last changed', (done) ->
    req.doc.data.endret = '2013-01-01T01:01:01.010Z'

    document.all req, res, (err) ->
      assert.ifError err
      assert.equal res.headers['Last-Modified'], 'Tue, 01 Jan 2013 01:01:01 GMT'
      done()

  it 'should deny PUT if user is not owner', (done) ->
    req.isOwner = false
    req.method = 'PUT'
    res.json = (code, body) ->
      assert.equal code, 403
      assert.deepEqual body, message: 'Request Denied'
      done()

    document.all req, res, assert.fail

  it 'should deny PATCH if user is not owner', (done) ->
    req.isOwner = false
    req.method = 'PATCH'
    res.json = (code, body) ->
      assert.equal code, 403
      assert.deepEqual body, message: 'Request Denied'
      done()

    document.all req, res, assert.fail

  it 'should deny DELETE if user is not owner', (done) ->
    req.isOwner = false
    req.method = 'DELETE'
    res.json = (code, body) ->
      assert.equal code, 403
      assert.deepEqual body, message: 'Request Denied'
      done()

    document.all req, res, -> assert false, 'next called'

  it 'should return 412 when If-Match != doc checksum', (done) ->
    req.headers['If-Match'] = '"6fa48eca48702c171c4bb6ef5e95dbbe"'
    res.status = (code) -> spy = true; assert.equal code, 412; @
    res.end = (err) -> assert.equal err, undefined; assert spy; done()

    document.all req, res, -> assert false, 'next called'

  it 'should return 304 when If-None-Match == doc checksum', (done) ->
    req.headers['If-None-Match'] = "\"#{req.doc.data.checksum}\""
    res.status = (code) -> spy = true; assert.equal code, 304; @
    res.end = (err) -> assert.equal err, undefined; assert spy; done()

    document.all req, res, -> assert false, 'next called'

  it 'should return 304 when If-Modified-Since >= doc last change', (done) ->
    req.headers['If-Modified-Since'] = 'Sun, 12 Jan 2014 08:49:37 GMT'
    res.status = (code) -> spy = true; assert.equal code, 304; @
    res.end = (err) -> assert.equal err, undefined; assert spy; done()

    document.all req, res, -> assert false, 'next called'

  it 'should return 412 when If-Unmodified-Since < doc last cahnge', (done) ->
    req.headers['If-Unmodified-Since'] = 'Sun, 10 Nov 2013 08:49:37 GMT'
    res.status = (code) -> spy = true; assert.equal code, 412; @
    res.end = (err) -> assert.equal err, undefined; assert spy; done()

    document.all req, res, -> assert false, 'next called'

  it 'should ignore If-Modified-Since if If-Match is set'
  it 'should ignore If-Unmodified-Since if If-Match is set'
  it 'should ignore If-None-Match if If-Match is set'

  it 'should ignore If-Modified-Since if If-None-Match is set', (done) ->
    req.headers['If-None-Match'] = '"6fa48eca48702c171c4bb6ef5e95dbbe"'
    req.headers['If-Modified-Since'] = 'Sun, 12 Jan 2014 08:49:37 GMT'

    document.all req, res, done

  it 'should ignore If-Unmodified-Since if If-None-Match is set', (done) ->
    req.headers['If-None-Match'] = '"6fa48eca48702c171c4bb6ef5e95dbbe"'
    req.headers['If-Unmodified-Since'] = 'Sun, 10 Nov 2013 08:49:37 GMT'

    document.all req, res, done

describe '#options()', ->
  it 'should set Access-Control-Allow-Headers', (done) ->
    res.send = (code) ->
      assert.equal res.headers['Access-Control-Allow-Methods'], [
        'HEAD', 'GET', 'PUT', 'PATCH', 'DELETE'
      ].join ', '
      done()

    document.options req, res, -> assert false, 'next() called'

  it 'should set Access-Control-Allow-Methods', (done) ->
    res.send = (code) ->
      assert.equal res.headers['Access-Control-Allow-Headers'], [
        'Content-Type'
        'If-Match'
        'If-Modified-Since'
        'If-None-Match'
        'If-Unmodified-Since'
      ].join ', '
      done()

    document.options req, res, -> assert false, 'next() called'

  it 'should return 204 status code', (done) ->
    res.send = (code) ->
      assert.equal code, 204
      done()

    document.options req, res, -> assert false, 'next() called'

describe '#get()', ->
  it 'should return no body for HEAD', (done) ->
    req.method = 'HEAD'
    res.send = (code) ->
      assert.equal code, 200
      done()

    document.get req, res, -> assert false, 'next() called'

  it 'should handle doc.getFull() error', (done) ->
    req.doc.getFull = (filter, cb) ->
      cb new Error 'getFull failed'

    document.get req, res, (err) ->
      /getFull failed/.test err
      done()

  it 'should return doc data with private data for owner', (done) ->
    req.doc.getFull = (filter, cb) ->
      assert.deepEqual filter, {}
      cb null, foo: 'bar', privat: bar: 'foo'

    res.json = (code, body) ->
      assert.equal code, 200
      assert.deepEqual body, foo: 'bar', privat: bar: 'foo'
      done()

    document.get req, res, assert.ifError

  it 'should return doc data with no privat data for non owner', (done) ->
    req.isOwner = false

    req.doc.getFull = (filter, cb) ->
      assert.deepEqual filter, privat: false
      cb null, foo: 'bar'

    res.json = (code, body) ->
      assert.equal code, 200
      assert.deepEqual body, foo: 'bar'
      done()

    document.get req, res, assert.ifError

describe '#put()', ->
  beforeEach ->
    req.method = 'PUT'
    req.body = foo: 'bar'
    req.doc.replace = (body, cb) ->
      body.checksum = 'foo'
      body.endret = '2013-01-01T01:01:01.010Z'
      cb null, [], body

  it 'should return 400 if body is missing', (done) ->
    req.body = {}
    res.json = (code, body) ->
      assert.equal code, 400
      assert.deepEqual body, message: 'Body is missing'
      done()

    document.put req, res, assert.ifError

  it 'should return 400 if body is not object', (done) ->
    req.body = [{}]
    res.json = (code, body) ->
      assert.equal code, 400
      assert.deepEqual body, message: 'Body should be a JSON Hash'
      done()

    document.put req, res, assert.ifError

  it 'should replace doc data if method is PUT', (done) ->
    res.json = (code, body) -> done()
    req.doc.replace = (body, cb) ->
      assert.equal body.foo, 'bar'
      cb null, [], checksum: 'foo', endret: '2013-01-01T01:01:01.010Z'

    document.put req, res, assert.ifError

  it 'should update doc data if method is PATCH', (done) ->
    req.method = 'PATCH'
    req.body = $set: foo: 'bar'
    res.json = (code, body) -> done()
    req.doc.update = (body, cb) ->
      assert.equal body.$set.foo, 'bar'
      cb null, [], checksum: 'foo', endret: '2013-01-01T01:01:01.010Z'

    document.patch req, res, assert.ifError

  it 'should override data.tilbyder', (done) ->
    res.json = (code, body) -> done()
    req.doc.replace = (body, cb) ->
      assert.equal body.tilbyder, req.usr
      cb null, [], checksum: 'foo', endret: '2013-01-01T01:01:01.010Z'

    document.put req, res, assert.ifError

  it 'should return 422 if data schema fails', (done) ->
    req.body = navn: 123
    res.json = (code, body) ->
      assert.equal code, 422
      assert.equal body.message, 'Validation Failed'
      assert.deepEqual body.errors, [foo: 'bar']
      done()

    req.doc.replace = (body, cb) ->
      err = new Error('ValidationError')
      err.name = 'ValidationError'
      err.details = [foo: 'bar']
      cb err, [], checksum: 'foo', endret: '2013-01-01T01:01:01.010Z'

    document.put req, res, assert.ifError

  it 'should set ETag header', (done) ->
    res.json = ->
      assert.equal res.headers['ETag'], '"foo"'
      done()

    document.put req, res, assert.ifError

  it 'should set Last-Modified header', (done) ->
    res.json = ->
      assert.equal res.headers['Last-Modified'], 'Tue, 01 Jan 2013 01:01:01 GMT'
      done()

    document.put req, res, assert.ifError

  it 'should return 200 with body', (done) ->
    res.json = (code, body) ->
      assert.equal code, 200
      assert.deepEqual body,
        document:
          foo: 'bar'
          tilbyder: req.usr
          checksum: 'foo'
          endret: '2013-01-01T01:01:01.010Z'
        message: undefined
        warnings: undefined
      done()

    document.put req, res, assert.ifError

  it 'should return warnings if any', (done) ->
    res.json = (code, body) ->
      assert.equal code, 200
      assert.deepEqual body.message, 'Validation Warnings'
      assert.deepEqual body.warnings, [foo: 'bar']
      done()
    req.doc.replace = (data, cb) ->
      cb null, [foo: 'bar'], checksum: 'foo', endret: '2013-01-01T01:01:01.010Z'

    document.put req, res, assert.ifError

describe '#delete()', ->
  beforeEach ->
    req.method = 'DELETE'

  it 'should delete document', (done) ->
    req.doc.delete = -> done()
    document.delete req, res, assert.ifError

  it 'should handle doc.delete() error', (done) ->
    req.doc.delete = (cb) -> cb new Error 'delete failed'
    document.delete req, res, (err) ->
      /delete failed/.test err
      done()

  it 'should return 204 with no body', (done) ->
    req.doc.delete = (cb) -> cb null
    res.send = (code) ->
      assert.equal code, 204
      done()

    document.delete req, res, assert.ifError


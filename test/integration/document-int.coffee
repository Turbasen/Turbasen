request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

steder = turer = null
before ->
  steder = module.parent.exports.steder
  turer = module.parent.exports.turer

describe 'OPTIONS', ->
  url = '/steder/53507fb375049e5615000181?api_key=nrk'

  it 'should return 204 status code with no body', (done) ->
    req.options url
      .expect 204, {}
      .end done

  it 'should return access-control headers', (done) ->
    req.options url
      .expect 204, {}
      .expect 'access-control-allow-methods', 'HEAD, GET, PUT, PATCH, DELETE'
      .end done

describe 'GET', ->
  it 'should return 404 for missing document', (done) ->
    req.get '/steder/53507fb375049e5615000181?api_key=dnt'
      .expect 404, message: 'Not Found', done

  it 'should return 200 for public document', (done) ->
    req.get '/steder/52407fb375049e5615000170?api_key=dnt'
      .expect (res) ->
        assert.equal res.statusCode, 200
        assert.equal typeof res.body, 'object'
        assert.equal typeof res.body.privat, 'object'
      .end done

  it 'should not return private data for non owner', (done) ->
    req.get '/steder/52407fb375049e5615000170?api_key=nrk'
      .expect (res) ->
        assert.equal res.statusCode, 200
        assert.equal typeof res.body, 'object'
        assert.equal typeof res.body.privat, 'undefined'
      .end done

  it 'should return 200 for private document for owner', (done) ->
    req.get '/steder/52d65b2544db971c94b2d949?api_key=dnt'
      .expect (res) ->
        assert.equal res.statusCode, 200
        assert.equal typeof res.body, 'object'
        assert.equal typeof res.body.privat, 'object'
      .end done

  it 'should return 404 for private document for non owner', (done) ->
    req.get '/steder/52d65b2544db971c94b2d949?api_key=nrk'
      .expect 404, message: 'Not Found', done

describe 'HEAD', ->
  it 'should return 404 with no body for missing document', (done) ->
    req.head '/steder/53507fb375049e5615000181?api_key=dnt'
      .expect 404, {}, done

  it 'should return 200 with no body for existing document', (done) ->
    req.head '/steder/52407fb375049e5615000170?api_key=dnt'
      .expect 200, {}, done

describe 'PUT', ->
  it 'should return 403 for non owner', (done) ->
    req.put '/steder/52407fb375049e5615000170?api_key=nrk'
      .expect 403, message: 'Request Denied', done

  it 'should return 200 for owner', (done) ->
    req.put '/steder/52407fb375049e5615000170?api_key=dnt'
      .send navn: 'Foo'
      .expect (res) ->
        assert.equal res.statusCode, 200
        assert.equal typeof res.body.document, 'object'
        assert.equal res.body.document.navn, 'Foo'
      .end done

describe 'PATCH', ->
  it 'should return 403 for non owner', (done) ->
    req.patch '/steder/52407fb375049e5615000170?api_key=nrk'
      .expect 403, message: 'Request Denied', done

  it 'should return 200 for owner', (done) ->
    req.patch '/steder/52407fb375049e5615000170?api_key=dnt'
      .send $set: navn: 'Foo'
      .expect (res) ->
        assert.equal res.statusCode, 200
        assert.equal typeof res.body.document, 'object'
        assert.equal res.body.document.navn, 'Foo'
      .end done

describe 'DELETE', ->
  it 'should return 403 for non owner', (done) ->
    req.delete '/steder/52407fb375049e5615000170?api_key=nrk'
      .expect 403, message: 'Request Denied', done

  it 'should return 204 for owner', (done) ->
    req.delete '/steder/52407fb375049e5615000170?api_key=dnt'
      .expect 204, {}, done

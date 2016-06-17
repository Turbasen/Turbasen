request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

steder = turer = null
before ->
  steder = module.parent.exports.steder
  turer = module.parent.exports.turer

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

  it 'should return single expanded field', (done) ->
    req.get '/steder/52d65b2544db971c94b2d949?expand=grupper&api_key=dnt'
      .expect 200
      .expect (res) ->
        assert.equal res.body.grupper.length, 1
        assert.equal typeof res.body.grupper[0], 'object'
      .end done

  it 'should return multiple expanded fields', (done) ->
    req.get '/steder/52407fb375049e5615000170?expand=bilder,områder&api_key=dnt'
      .expect 200
      .expect (res) ->
        assert.equal res.body.bilder.length, 3
        assert.equal res.body.områder.length, 3
        assert.equal typeof res.body.bilder[0], 'object'
        assert.equal typeof res.body.områder[0], 'object'
      .end done

  it 'should hide private sub-documents from non-owners', (done) ->
    req.get '/steder/52407fb375049e5615000170?expand=bilder,områder&api_key=nrk'
      .expect 200
      .expect (res) ->
        assert.equal res.body.bilder.length, 2
        assert.equal res.body.områder.length, 2
      .end done

  it 'should hide private fields from sub-documents', (done) ->
    req.get '/steder/52407fb375049e5615000170?expand=bilder,områder&api_key=nrk'
      .expect 200
      .expect (res) ->
        assert.equal typeof res.body.bilder[0].privat, 'undefined'
        assert.equal typeof res.body.bilder[1].privat, 'undefined'
        assert.equal typeof res.body.områder[0].privat, 'undefined'
        assert.equal typeof res.body.områder[1].privat, 'undefined'
      .end done

  it 'should return only specified sub-document fields', (done) ->
    url = '/steder/52407fb375049e5615000170'
    req.get "#{url}?expand=bilder&fields=tags&api_key=dnt"
      .expect 200
      .expect (res) ->
        assert.equal typeof res.body.bilder[0].tags, 'object'
        assert.equal typeof res.body.bilder[1].tags, 'object'
        assert.equal typeof res.body.bilder[2].tags, 'object'

        assert.equal typeof res.body.bilder[0].src, 'undefined'
        assert.equal typeof res.body.bilder[1].src, 'undefined'
        assert.equal typeof res.body.bilder[2].src, 'undefined'
      .end done

  it 'should limit the number of sub documents returned', (done) ->
    url = '/steder/52407fb375049e5615000170'
    req.get "#{url}?expand=bilder,områder&limit=1&api_key=dnt"
      .expect 200
      .expect (res) ->
        assert.equal res.body.bilder.length, 1
        assert.equal res.body.områder.length, 1
        assert.equal typeof res.body.bilder[0], 'object'
        assert.equal typeof res.body.områder[0], 'object'
      .end done

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

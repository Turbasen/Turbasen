request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

describe 'OPTIONS', ->
  url = '/steder?api_key=dnt'

  it 'should return 204 status code with no body', (done) ->
    req.options url
      .expect 204, {}
      .end done

  it 'shoould return correct headers', (done) ->
    req.options url
      .expect 204, {}
      .expect 'access-control-expose-headers', [
        'ETag', 'Location', 'Last-Modified', 'Count-Return', 'Count-Total'
      ].join(', ')
      .expect 'access-control-max-age', '86400'
      .expect 'access-control-allow-headers', 'Content-Type'
      .expect 'access-control-allow-methods', 'HEAD, GET, POST'
      # Access-Control-Allow-Origin
      # Strict-Transport-Security
      # X-Content-Type-Options: nosniff
      # Vary: Accept-Encoding
      .end done

describe 'HEAD', ->
  url = '/turer?api_key=dnt'

  it 'should return 204 status code with no body', (done) ->
    req.head url
      .expect 204, {}
      .end done

  it 'should return correct headers', (done) ->
    req.head(url)
      .expect 204, {}
      .expect 'count-return', '20'
      .expect 'count-total', '27'
      .end done

describe 'GET', ->
  it 'should return 200 status code with documents', (done) ->
    req.get '/steder?api_key=dnt'
      .expect 200
      .expect (res) ->
        assert res.body.documents instanceof Array
        assert.equal res.body.count, 20
      .end done

  describe '?limit', ->
    it 'should limit number of documents returned', (done) ->
      req.get '/steder?limit=10&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 10
        .end done

    it 'should prevent limit higher then 50', (done) ->
      req.get '/steder?limit=100&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 50
        .end done

  describe '?skip', ->
    it 'should skip the 9 first documents', (done) ->
      req.get('/steder?api_key=dnt').end (err, res1) ->
        assert.ifError err
        skip = res1.body.documents.length - 1

        req.get("/steder?skip=#{skip}&api_key=dnt").end (err, res2) ->
          assert.ifError err
          assert.deepEqual res1.body.documents[skip], res2.body.documents[0]
          done()

    it 'should skip majority of total number of documents', (done) ->
      req.get '/steder?skip=110&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 10
          assert.equal res.body.total, 120
          assert.equal res.body.documents.length, 10
        .end done

    it 'should skip past total number of documents', (done) ->
      req.get '/steder?skip=130&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 0
          assert.equal res.body.total, 120
          assert.equal res.body.documents.length, 0
        .end done

  describe '?tag', ->
    it 'should return documents matching tag', (done) ->
      req.get '/turer?tag=Skitur&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 2
          assert.equal sted.tags[0], 'Skitur' for sted in res.body.documents
          return
        .end done

    it 'should return documents not matching tag', (done) ->
      req.get '/turer?tag=!Fottur&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 2
          assert.notEqual tur.tags[0], 'Fottur' for tur in res.body.documents
          return
        .end done

  describe '?gruppe', ->
    it 'should filter based on gruppe', (done) ->
      gruppe = '52407f3c4ec4a1381500025d'
      req.get "/steder?gruppe=#{gruppe}&api_key=dnt"
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 20
          assert.equal res.body.total, 26
          #assert gruppe in doc.grupper for doc in res.body.documents
          return
        .end done

  describe '?after', ->
    documentCount = (count, res) ->
      assert.equal res.body.count, count

    documentAfter = (after, res) ->
      for doc in res.body.documents
        assert doc.endret >= after, "#{doc.endret} >= #{after}"
      return

    it 'should return documents changed after UTZ datestamp', (done) ->
      date = '2014-06-01T17:42:39.766Z'
      req.get "/turer?after=#{date}&api_key=dnt"
        .expect 200
        .expect documentCount.bind(undefined, 10)
        .expect documentAfter.bind(undefined, date)
        .end done

    it 'should return documents changed after millis from 1.1.1970', (done) ->
      date = new Date '2014-06-01T17:42:39.766Z'
      req.get "/turer?after=#{date.getTime()}&api_key=dnt"
        .expect 200
        .expect documentCount.bind(undefined, 10)
        .expect documentAfter.bind(undefined, date.toISOString())
        .end done

  describe '?bbox', ->
    it 'should return documents within bbox', (done) ->
      coords = '5.3633880615234375,60.777937176256515,6.52862548828125,61.044326483979894'
      req.get "/steder?bbox=#{coords}&api_key=dnt"
        .expect 200
        .expect (res) ->
          assert.equal res.statusCode, 200
          assert.equal res.body.count, 7
          # assert geometry for doc in res.body.documents
          return
        .end done

  describe '?privat.', ->
    it 'should return documents matching private property', (done) ->
      req.get '/steder?privat.opprettet_av.id=3456&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.statusCode, 200
          assert.equal res.body.count, 17
          # assert.equal doc.privat.opprettet_av.id, 3456 for doc in res.body.documents
          return
        done()

describe 'POST', ->
  url = '/turer?api_key=dnt'

  it 'should return 400 status code for missing body', (done) ->
    req.post url
      .expect 400, message: 'Body is missing'
      .end done

  it 'should return 402 status code for invalid body type', (done) ->
    req.post url
      .send ['foo', 'bar']
      .expect 422, message: 'Body should be a JSON Hash'
      .end done

  it 'should return 402 status code for invalid data schema', (done) ->
    req.post url
      .send navn: 123
      .expect 422
      .expect (res) ->
        assert.equal typeof res.body.document, 'object'
        assert.equal typeof res.body.errors, 'object'
        assert.deepEqual res.body.message, 'Validation Failed'
      .end done

  it 'should return 201 status code for successfull post', (done) ->
    req.post url
      .send navn: 'Test'
      .expect 201
      .expect 'etag', /^"[0-9a-f]{40}"$/
      .expect 'last-modified', /\w/
      .expect (res) ->
        assert.equal res.body.document.navn, 'Test'
      .end done

  it 'shoudl return warnings for missing data fileds', (done) ->
    req.post url
      .send navn: 'Test'
      .expect 201
      .expect (res) ->
        assert.equal res.body.message, 'Validation Warnings'
        assert.deepEqual res.body.warnings, [
          {resource: 'Document', field: 'lisens', code: 'missing_field'}
          {resource: 'Document', field: 'navngiving', code: 'missing_field'}
          {resource: 'Document', field: 'status', code: 'missing_field'}
        ]
      .end done

for method in ['put', 'patch', 'delete']
  describe method.toUpperCase(), ->
    it 'should return 405 Method Not Allowed status', (done) ->
      req[method]('/steder?api_key=dnt')
        .expect 405, message: "HTTP Method #{method.toUpperCase()} Not Allowed"
        .end done


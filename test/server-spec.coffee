assert = require 'assert'
request = require 'supertest'

app = require './../coffee/server'

describe 'API keys', ->
  it 'should return 403 error for no API key', (done) ->
    request(app)
      .get('/')
      .expect(403)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.err, 'AuthenticationFailed'
        done()

  it 'should return 403 error for invalid API key', (done) ->
    request(app)
      .get('/?api_key=test')
      .expect(403)
      .end (err, res) ->
        throw err if err
        assert.equal res.body.err, 'AuthenticationFailed'
        done()

  it 'should grant access to valid API key', (done) ->
    request(app)
      .get('/?api_key=dnt')
      .expect(200, done)

describe '/objekttyper', ->
  it 'should return a list of the different types', (done) ->
    request(app)
      .get('/objekttyper?api_key=dnt')
      .expect(200)
      .end (err, res) ->
        throw err if err

        assert.equal typeof res.body.types, 'object', 'types should be an object'
        assert.equal typeof res.body.count, 'number', 'count should be a number'
        assert.equal res.body.types.length, res.body.count, 'types.length and count should be equal'

        done()

describe.skip '/:object/', ->
  describe 'HTTP GET', ->
    it 'should return objects', (done) ->
      app.set 'debug', true
      request(app)
        .get('/turer/?api_key=dnt')
        #.expect(200, done)
        .end (err, res) ->
          console.log res.body

describe '/:object/:id', ->

  before (done) ->
    this.timeout 2000
    setTimeout ->
      done()
    ,1500

  it 'should return error for invalid document id', (done) ->
    request(app)
      .get('/turer/123/?api_key=dnt')
      .expect(400)
      .end (err, res) ->
        throw err if err

        assert.equal typeof res.body.err, 'string', 'err should be string'
        assert.equal res.body.err, 'ObjectIDMustBe24HexChars', 'err should equal ObjectIDMustBe24HexChars'

        done()
  
  describe 'HTTP GET', ->
    it 'should return existing document', (done) ->
      app.set 'debug', true
      request(app)
        .get('/turer/51c7fccf57a4f9770f528841/?api_key=dnt')
        .expect(200)
        .end (err, res) ->
          throw err if err

          assert.equal typeof res.body, 'object', 'document should be an object'
          assert.equal res.body._id, '51c7fccf57a4f9770f528841', 'document._id should equal request id'
          assert.equal typeof res.body.privat, 'object', 'document.privat should be a document'

          done()



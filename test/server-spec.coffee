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

describe.skip '/turer', ->
  describe 'HTTP GET', ->
    it 'should return objects', (done) ->
      app.set 'debug', true
      request(app)
        .get('/turer/?api_key=dnt')
        #.expect(200, done)
        .end (err, res) ->
          console.log res.body


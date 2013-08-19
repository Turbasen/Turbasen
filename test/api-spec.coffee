assert = require 'assert'
request = require 'supertest'

app = require './../coffee/nasjonalturbase.api'

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

    

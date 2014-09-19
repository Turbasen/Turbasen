request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

describe '?api_key', ->
  it 'should fail with no api key', (done) ->
    req.get('/').expect(403).end (err, res) ->
        assert.ifError err
        assert.equal res.body.message, 'API key missing'
        done()

  it 'should fail for invalid api key', (done) ->
    req.get('/?api_key=fail').expect(401).end (err, res) ->
        assert.ifError err
        assert.equal res.body.message, 'API key invalid'
        done()

  it 'should authenticate for valid api key', (done) ->
    req.get('/?api_key=dnt').expect(200).end (err, res) ->
        assert.ifError err
        assert.equal res.body.message, 'Here be dragons'
        done()


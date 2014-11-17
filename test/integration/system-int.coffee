request   = require 'supertest'
assert    = require 'assert'

req = request require '../../coffee/server'

describe '/CloudHealthCheck', ->
  it 'should return 200 OK for GET request', (done) ->
    req.get '/CloudHealthCheck'
      .expect 200
      .expect (res) ->
        assert.deepEqual res.body, message: 'System OK'
      .end done

  it 'should return 200 OK for HEAD request', (done) ->
    req.get('/CloudHealthCheck').expect(200).end done


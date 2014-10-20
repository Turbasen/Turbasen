request   = require 'supertest'
assert    = require 'assert'

req = request require '../../coffee/server'

describe '/CloudHealthCheck', ->
  it 'should return OK for MongoDB and Redis', (done) ->
    req.get '/CloudHealthCheck'
      .expect 200
      .expect (res) ->
        assert.deepEqual res.body, message: 'System OK'
      .end done


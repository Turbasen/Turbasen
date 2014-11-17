request = require 'supertest'
assert  = require 'assert'

redis   = require '../../coffee/db/redis'

req     = request require './../../coffee/server'

describe '?api_key', ->
  it 'should return 200 for valid API key', (done) ->
    req.get '/?api_key=dnt'
      .expect 200
      .expect 'X-RateLimit-Limit', 1000
      .expect 'X-RateLimit-Remaining', 999
      .expect 'X-RateLimit-Reset', /^[0-9]{10}$/
      .end done

  it 'should return 401 for no API key', (done) ->
    req.get '/'
      .expect 401
      .expect (res) ->
        assert.deepEqual res.body, message: 'Bad credentials'
      .end done

  it 'should return 401 for invalid API key', (done) ->
    req.get '/'
      .expect 401
      .expect (res) ->
        assert.deepEqual res.body, message: 'Bad credentials'
      .end done

  it 'should return 403 when rate limit is exceeded', (done) ->
    req.get '/?api_key=dnt'
      .expect 200
      .end (err, res, body) ->
        assert.ifError err

        # @TODO This is a bit hacky! Maybe there is a better way?
        redis.hset 'api.users:dnt', 'remaining', 0

        req.get '/?api_key=dnt'
          .expect 403
          .expect 'X-RateLimit-Limit', 1000
          .expect 'X-RateLimit-Remaining', 0
          .expect 'X-RateLimit-Reset', /^[0-9]{10}$/
          .expect (res) ->
            assert.deepEqual res.body, message: 'API rate limit exceeded'
          .end done


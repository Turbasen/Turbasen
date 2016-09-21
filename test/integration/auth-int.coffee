request = require 'supertest'
assert  = require 'assert'

redis = require '@turbasen/db-redis'
mongo = require '@turbasen/db-mongo'

req   = request require './../../coffee/server'

describe '?api_key', ->
  it 'returns 200 for no API authentication', ->
    req.get '/'
      .expect 200
      .expect 'X-User-Auth', 'false'
      .expect 'X-RateLimit-Limit', '100'
      .expect 'X-RateLimit-Remaining', '99'
      .expect 'X-RateLimit-Reset', /^[0-9]{10}$/

  it 'returns 200 for valid API key (Authorization header)', ->
    req.get '/'
      .set 'Authorization', 'token dnt'
      .expect 200
      .expect 'X-User-Auth', 'true'
      .expect 'X-User-Provider', 'DNT'
      .expect 'X-RateLimit-Limit', '1000'
      .expect 'X-RateLimit-Remaining', '999'
      .expect 'X-RateLimit-Reset', /^[0-9]{10}$/

  it 'returns 200 for valid API key (api_key param)', ->
    req.get '/?api_key=dnt'
      .expect 200
      .expect 'X-User-Auth', 'true'
      .expect 'X-User-Provider', 'DNT'
      .expect 'X-RateLimit-Limit', '1000'
      .expect 'X-RateLimit-Remaining', '999'
      .expect 'X-RateLimit-Reset', /^[0-9]{10}$/

  it 'should return 401 for invalid API key', ->
    req.get '/'
      .set 'Authorization', 'token invalid'
      .expect 401
      .expect message: 'Bad credentials for user "invalid"'

  it 'should return 403 when rate limit is exceeded', (done) ->
    req.get '/?api_key=dnt'
      .expect 200
      .end (err, res, body) ->
        assert.ifError err

        AuthUser = require('@turbasen/auth').AuthUser
        new AuthUser('dnt', {
          provider: 'DNT'
          app: 'dnt_app1'
          limit: 1000
          remaining: 0
          reset: 9999999999
        }).save()

        req.get '/?api_key=dnt'
          .expect 403
          .expect 'X-User-Auth', 'true'
          .expect 'X-User-Provider', 'DNT'
          .expect 'X-RateLimit-Limit', '1000'
          .expect 'X-RateLimit-Remaining', '0'
          .expect 'X-RateLimit-Reset', /^[0-9]{10}$/
          .expect (res) ->
            assert.deepEqual res.body,
              message: 'API rate limit exceeded for token "dnt"'
          .end done

    return

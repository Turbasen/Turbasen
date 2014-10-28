redis = require '../../../coffee/db/redis'

auth = require '../../../coffee/helper/auth'
assert = require 'assert'

describe 'getUser()', ->
  it 'should return non-existing user for unknown API key', (done) ->
    auth.getUser 'foo', (err, user) ->
      assert.ifError err
      assert.deepEqual user, remaining: 0
      done()

  it 'should return user for known API key', (done) ->
    auth.getUser 'dnt', (err, user) ->
      assert.ifError err
      assert.equal user.tilbyder, 'DNT'
      assert.equal user.limit, 1000
      assert.equal user.remaining, 1000
      assert user.reset > Math.floor new Date().getTime() / 1000
      done()

  it 'should cache existing user for 1 hour', (done) ->
    key = 'dnt'
    auth.getUser key, (err, user) ->
      assert.ifError err
      # @TODO this is hard-coded
      redis.ttl "api.users:#{key}", (err, ttl) ->
        assert.ifError err
        assert.equal ttl, 1 * 60 * 60
        done()

  it 'should cache non-existing user for 24 hours', (done) ->
    key = 'foo'
    auth.getUser key, (err, user) ->
      assert.ifError err

      # @TODO this is hard-coded
      redis.ttl "api.users:#{key}", (err, ttl) ->
        assert.ifError err
        assert.equal ttl, 24 * 60 * 60
        done()

  it 'should return cached user for known API key', (done) ->
    key = 'dnt'
    auth.getUser key, (err) ->
      assert.ifError err

      # @TODO this is hard-coded
      redis.hset "api.users:#{key}", "foo", "bar", (err) ->
        assert.ifError err

        auth.getUser key, (err, user) ->
          assert.ifError err

          assert.equal user.foo, 'bar'
          done()

describe 'chargeUser()', (done) ->
  it 'should decrement returned remaining rate limit by 1', (done) ->
    key = 'dnt'
    auth.getUser key, (err, user) ->
      assert.ifError err

      assert.equal user.remaining, 1000
      user = auth.chargeUser key, user
      assert.equal user.remaining, 999

      done()

  it 'should decrement cached user remaining rate limit by 1', (done) ->
    key = 'dnt'
    auth.getUser key, (err, user) ->
      assert.ifError err

      assert.equal user.remaining, 1000
      auth.chargeUser key, user

      redis.hgetall "api.users:#{key}", (err, user) ->
        assert.ifError err
        assert.equal user.remaining, 999

        done()

describe 'check()', ->
  it 'should return user for valid API key', (done) ->
    auth.check 'dnt', (err, user) ->
      assert.ifError err

      assert.deepEqual Object.keys(user), ['tilbyder','limit','remaining','reset']
      assert.equal user.tilbyder, 'DNT'
      assert.equal user.remaining, 999
      assert.equal user.limit, 1000
      assert.equal typeof user.reset, 'number'

      done()

  it 'should set induvidual rate limit per user', (done) ->
    key = 'abc'
    auth.check key, (err, user) ->
      assert.ifError err
      assert.equal user.limit, 500

      done()

  it 'should decrement remaining user rate limit by 1', (done) ->
    key = 'dnt'
    auth.check key, (err, user) ->
      assert.ifError err
      assert.equal user.remaining, 999

      auth.check key, (err, user) ->
        assert.ifError err
        assert.equal user.remaining, 998

        done()

  it 'should return error for no API key', (done) ->
    auth.check undefined, (err, user) ->
      assert.equal err.message, 'Bad credentials'
      assert.equal err.status, 401

      done()

  it 'should return error for invalid API key', (done) ->
    auth.check 'foo', (err, user) ->
      assert.equal err.message, 'Bad credentials'
      assert.equal err.status, 401

      done()

  it 'should return error when API limit is exceeded', (done) ->
    key = 'dnt'
    auth.check key, (err, user) ->
      assert.ifError err

      # @TODO this is hard-coded
      redis.hset "api.users:#{key}", "remaining", 0, (err, user) ->
        assert.ifError err

        auth.check key, (err, user) ->
          assert.equal err.message, 'API rate limit exceeded'
          assert.equal err.status, 403

          done()


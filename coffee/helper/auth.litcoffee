    mongo   = require '../db/mongo'
    redis   = require '../db/redis'

## check()

Check if API key is a valid API user and check rate limit quota.

### Params

* `string` key - API key
* `function` cb - callback function (`Error` err, `object` user)

### Return

Returns `undefined`

    exports.check = (key, cb) ->
      exports.getUser key, (err, user) ->
        return cb err if err

        if not user.tilbyder or user.tilbyder is 'Ukjent'
          err = new Error 'Bad credentials'
          err.status = 401
          return cb err

        if user.remaining < 1
          err = new Error 'API rate limit exceeded'
          err.status = 403
          return cb err, user

        return cb null, exports.chargeUser key, user

## chargeUser()

Update user rate limit quota.

### Params

* `string` key - API key
* `object` user - API user

### Return

Returns an updated API user `object`.

    exports.chargeUser = (key, user) ->
      user.remaining--
      redis.hincrby "api:users:#{key}", 'remaining', -1

      return user

## getUser()

Get API user for API key, either from cache or from database.

### Params

* `string` key - API key
* `function` cb - callback function (`Error` err, `object` user)

### Return

Returns `undefined`.

    exports.getUser = (key, cb) ->
      return cb null, remaining: 0 if not key

First; check if API user exists in Redis cache.

      redis.hgetall "api:users:#{key}", (err, user) ->
        return cb err if err

        # There exist an edge case when the key is expired before changeUser()
        # has been called. In this case only the "remainig" field is set and
        # the key is never expired after that. Here we check that the key is
        # valid by explicitly checking for the "tilbyder" field.

        return cb null, user if user and user.tilbyder

Fallback; get API user from MongoDB database.

        query = {}
        query["keys.#{key}"] = $exists: true

        mongo['api.users'].findOne query, (err, doc) ->
          return cb err if err

Add existing user and rate limit information to Redis cache. Set cache expire
time to 1 hour.

          if doc
            expire = Math.floor (new Date().getTime() + 3600000) / 1000
            user =
              tilbyder  : doc.provider
              limit     : doc.keys[key].limit
              remaining : doc.keys[key].limit
              reset     : expire

Add non-existing user to Redis cache with `0` remaining rate limit. Set cache
expire time to 24 hours.

          else
            expire = Math.floor (new Date().getTime() + 86400000) / 1000
            user = tilbyder: 'Ukjent', remaining: 0

Add user to Redis cache and apply expire time before returning the user
object.

          redis.hmset "api:users:#{key}", user
          redis.expireat "api:users:#{key}", expire

          cb null, user


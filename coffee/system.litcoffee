    async = require 'async'

    redis = require './db/redis'
    mongo = require './db/mongo'

## check()

This is the system check. It retrives the current status from Redis and MongoDB
and perfoms a simple error checking on the returned data before returning to the
user.

Since this is publicly available endpoint, no data is returned, only a `System
OK` message if everything is fine. Errors are logged.

    exports.check = (req, res, next) ->
      async.parallel
        Mongo: mongo.db.command.bind mongo.db, dbStats: true
        Redis: redis.info.bind redis

      , (err, result) ->
        return next err if err
        return res.json 200, message: 'System OK'


    redis = require './db/redis'
    mongo = require './db/mongo'

## check()

This is the system check. It retrives the current status from Redis and MongoDB
and perfoms a simple error checking on the returned data before returning to the
user.

Since this is publicly available endpoint, no data is returned, only a `System
OK` message if everything is fine. Errors are logged.

    exports.check = (req, res, next) ->
      cnt = 0
      ret = (err, info) ->
        return if cnt > 2

        if err
          cnt = Math.Infinity
          next err

        else if ++cnt is 2
          res.json 200, message: 'System OK'

      mongo.db.command dbStats: true, ret
      redis.info ret


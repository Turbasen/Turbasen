    mongo   = require '../db/mongo'
    redis   = require '../db/redis'

This is the dirty part. Here are all the keys to the kingdom. These will be
moved to the database and retrieved when the server starts. Just need to find
the time to do it.

    keys =
      dnt: 'DNT'
      nrk: 'NRK'

      '30ad3a3a1d2c7c63102e09e6fe4bb253': 'TurApp'
      'b523ceb5e16fb92b2a999676a87698d1': 'Pingdom'

      '4c802ac2315ab24db9c992cc6eea0278': 'DNT' # ETA
      'de2986ac75c5af9d7f92a26f37dc1b77': 'DNT' # sherpa2.api
      '5dd5a39057cb479c3c4bce7f9eae5e6c': 'DNT' # dev.ut.no
      '146bbe01b477e9e07e85e0ddd3f5095a': 'DNT' # beta.ut.no
      'e6fa27292ffbcc689c49179c47bc708e': 'DNT' # prod.ut.no

    exports.check = (key, cb) ->
      process.nextTick ->
        cb null, keys[key]


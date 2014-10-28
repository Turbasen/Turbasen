EventEmitter = require('events').EventEmitter
MongoClient = require('mongodb').MongoClient
inherits = require('util').inherits

Mongo = (uri) ->
  EventEmitter.call @

  new MongoClient.connect uri, (err, database) =>
    throw err if err
    @db = database

    for col in ['arrangementer', 'bilder', 'grupper', 'områder', 'turer', 'steder', 'api.users']
      @[col] = @db.collection col

    @emit 'ready'

  @

inherits Mongo, EventEmitter

module.exports = new Mongo(process.env.MONGO_URI)


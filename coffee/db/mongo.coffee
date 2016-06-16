EventEmitter = require('events').EventEmitter
MongoClient = require('mongodb').MongoClient
inherits = require('util').inherits
collections = require('./../helper/schema').types

Mongo = (uri) ->
  EventEmitter.call @

  new MongoClient.connect uri, (err, database) =>
    throw err if err
    @db = database

    for col in collections.concat ['api.users']
      @[col] = @db.collection col

    @emit 'ready'

  @

inherits Mongo, EventEmitter
process.env.MONGO_URI ?= "mongodb://\
                          #{process.env.MONGO_PORT_27017_TCP_ADDR}:\
                          #{process.env.MONGO_PORT_27017_TCP_PORT}/test"

module.exports = new Mongo process.env.MONGO_URI

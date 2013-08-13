"use strict"

MongoClient = require('mongodb').MongoClient
format = require('util').format

#
# Connect to database
#
# @param {@code String} collection - collection name
# @param {@code Function} cb - callback function (err, db)
#
# github.com/mongodb/node-mongodb-native/blob/master/docs/articles/MongoClient.md
#
exports.connect = (database, cb) ->
  database = database || 'ntb_07'
  host = process.env['MONGO_NODE_DRIVER_HOST'] || 'localhost'
  port = process.env['MONGO_NODE_DRIVER_PORT'] || 27017
  url  = format "mongodb://%s:%s,%s:%s,%s:%s/%s", host, port, host, port+1, host, port+2, database

  MongoClient.connect url, (err, db) ->
    db.close() if err
    return cb err, db

#
# Process documents syncronously
#
# @param {@code Object} cursor - active mongodb cursor
# @param {@code Function} each - document processing function (doc, cb)
# @param {@code Functuon} done - done callback function (err)
#
# @todo add counter
# @todo add success, fail calbacks?
#
exports.each = (cursor, each, done) ->
  next = (i) ->
    return done null, i if cursor.queryRun and cursor.totalNumberOfRecords is i
    cursor.nextObject (err, doc) ->
      return done err, i if err
      return done null, i if doc is null
      each doc, (err) ->
        return done err, i if err
        next(++i)
  next(0)


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
exports.connect = (custom_uri, cb) ->
  switch process.env['MODE']
    when "production" then uri = process.env['MONGO_PROD_URI']
    when "stage" then uri = process.env['MONGO_STAGE_URI']
    when "development" then uri = process.env['MONGO_DEV_URI']
    else uri = "mongodb://localhost:27017/ntb_test"

  uri = custom_uri if custom_uri isnt null

  MongoClient.connect uri, (err, db) ->
    cb err, db

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
exports.each = (cursor, fn, done) ->
  next = (i, count) ->
    return done null, --i, count if i is count
    cursor.nextObject (err, doc) ->
      return done err, i, count if err
      return done null, i, count if doc is null
      fn doc, i, count, (err) ->
        return done err, i, count if err
        next(++i, count)

  cursor.count (err, count) ->
    count = cursor.limitValue || count if count isnt 0
    return done err, 0, count if err or count is 0
    next 0, count
  

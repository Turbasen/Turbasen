mongodb = require 'mongodb'

#
# Connect to database
#
# @param {@code String} collection - collection name
# @param {@code Function} cb - callback function (err, db)
#
exports.connect = (collection, cb) ->
  collection = collection || 'ntb_07'

  replSet = new mongodb.ReplSet [
    new mongodb.Server '127.0.0.1', 27017, {}
    , new mongodb.Server '127.0.0.1', 27018, {}
    , new mongodb.Server '127.0.0.1', 27019, {}
  ]
  
  db = new mongodb.Db collection, replSet, {
    w: 0
  }
  
  db.open (err, db) ->
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


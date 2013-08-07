mongodb = require 'mongodb'

#
# Connect to database
#
# @param {@code String} collection - collection name
# @param {@code Function} cb - callback function (err, db)
#
module.exports = (collection, cb) ->
  collection = collection || 'ntb_07'

  replSet = new mongodb.ReplSet [
    new mongodb.Server '127.0.0.1', 27017, {}
    , new mongodb.Server '127.0.0.1', 27018, {}
    , new mongodb.Server '127.0.0.1', 27019, {}
  ]
   
  db = new mongodb.Db collection, replSet,
    native_parser: true
    journal      : true
  
  db.open (err, db) ->
    return cb err, db


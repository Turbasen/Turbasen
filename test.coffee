MongoClient = require('mongodb').MongoClient
format = require('util').format

host = process.env['MONGO_NODE_DRIVER_HOST'] || 'localhost'
port = process.env['MONGO_NODE_DRIVER_PORT'] || 27017

url = format 'mongodb://%s:%s,%s:%s,%s:%s/ntb_07'
    , host, port, host, 27018, host, 27019

opts =
  w: 1
  native_parser: true
  logger :
    error: console.log
    log: console.log
    debug: console.log

MongoClient.connect url, opts, (err, db) ->
  throw err if err
  console.log 'connected'
  
  db.on 'error', (err, db) ->
    console.log 'foo'
    console.log err
    db.close()

  db.on 'close', (err, db) ->
    console.log 'close'
    console.log err

  db.on 'parseError', (err, db) ->
    console.log 'parseError'
    console.log err
    db.close()

  db.collectionNames (err, collections) ->
    throw err if err
    console.log collections

  counter = 0
  collection = db.collection 'aktiviteter'
  collection.find().explain (err, doc) ->
    throw err if err
    if err or doc is null
      db.close()
      console.log 'finsih'
      return

    console.log doc
    thisDoesNotExists 'foo', 'bar', 123
    

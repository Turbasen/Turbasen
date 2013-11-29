MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID
redisClient = require('redis')

redis = redisClient.createClient()
mongo = null

exit = (msg, code) ->
  mongo.close ->
    redis.end()
    console.log msg if msg
    process.exit(code or 0)


MongoClient.connect 'mongodb://localhost:27017/test', (err, db) ->
  throw err if err
  return exit('Usage: coffee docCheck.coffee type id', 1) if not process.argv[3]

  mongo = db
  type  = process.argv[2]
  id    = new ObjectID(process.argv[3])

  mongo.collection(type).findOne {_id: id}, (err, doc) ->
    throw err if err
    return exit('Document not found', 1) if not doc

    redis.hgetall "#{type}:#{id}", (err, data) ->
      console.log 'key', 'mongo', 'redis'
      for key in Object.keys doc
        console.log '-', key, doc[key], data[key]

      return exit()


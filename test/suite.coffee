async     = require 'async'

ObjectID  = require('mongodb').ObjectID
mongo     = require './../coffee/db/mongo'
redis     = require './../coffee/db/redis'

data =
  api: users: require './data/api.users.json'
  steder: require './data/steder.json'
  turer: require './data/turer.json'

# For some reason NodeJS or Mocha caches the object array but still tries to run
# the Object to ObjectID convertion. This results in new ObjectIDs for every run
# > 0. new ObjectID(ObjectID) => new ObjectId()

if not (data['steder'][0]._id instanceof ObjectID)
  for val, key in data.api.users
    data.api.users[key]._id = new ObjectID(val._id['$oid'])
  data.steder[key]._id = new ObjectID(val._id['$oid']) for val, key in data.steder
  data.turer[key]._id = new ObjectID(val._id['$oid']) for val, key in data.turer

exports.steder = JSON.parse JSON.stringify data.steder
exports.turer = JSON.parse JSON.stringify data.turer

# Wait for the MongoDB connection to become ready before spinning of any tests.

before (done) ->
  mongo.once 'ready', ->
    mongo.db.collection('api.users').drop()
    mongo.db.collection('api.users').insert data.api.users, (err) ->
      throw err if err
      done()

# Flush cache- and persistand data from Redis and MongoDB.

beforeEach (done) ->
  redis.flushall()

  mongo.steder.drop()
  mongo.turer.drop()

  async.series [
    mongo.steder.ensureIndex.bind(mongo.steder, {geojson: '2dsphere'})
    mongo.turer.ensureIndex.bind(mongo.turer, {geojson: '2dsphere'})
    mongo.steder.insert.bind(mongo.steder, data.steder)
    mongo.turer.insert.bind(mongo.turer, data.turer)
  ], (err) ->
    throw err if err
    done()

describe 'Unit Test', ->
  require './unit'

describe 'Integration Test', ->
  require './integration'

describe 'Acceptance Test', ->
  require './acceptance'

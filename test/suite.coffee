async     = require 'async'

ObjectID  = require('mongodb').ObjectID
mongo     = require './../coffee/db/mongo'
redis     = require './../coffee/db/redis'

data =
  api: users: require './data/api.users.json'
  bilder: require './data/bilder.json'
  grupper: require './data/grupper.json'
  områder: require './data/områder.json'
  steder: require './data/steder.json'
  turer: require './data/turer.json'

# For some reason NodeJS or Mocha caches the object array but still tries to run
# the Object to ObjectID convertion. This results in new ObjectIDs for every run
# > 0. new ObjectID(ObjectID) => new ObjectId()

if not (data['steder'][0]._id instanceof ObjectID)
  for val, key in data.api.users
    data.api.users[key]._id = new ObjectID(val._id['$oid'])

  for val, key in data.steder
    data.steder[key]._id = new ObjectID(val._id['$oid'])

  for val, key in data.turer
    data.turer[key]._id = new ObjectID(val._id['$oid'])

  for val, key in data.grupper
    data.grupper[key]._id = new ObjectID(val._id['$oid'])

  for val, key in data.områder
    data.områder[key]._id = new ObjectID(val._id['$oid'])

  for val, key in data.bilder
    data.bilder[key]._id = new ObjectID(val._id['$oid'])

exports.bilder = JSON.parse JSON.stringify data.bilder
exports.grupper = JSON.parse JSON.stringify data.grupper
exports.områder = JSON.parse JSON.stringify data.områder
exports.steder = JSON.parse JSON.stringify data.steder
exports.turer = JSON.parse JSON.stringify data.turer
exports.users = JSON.parse JSON.stringify data.api.users

# Wait for the MongoDB connection to become ready before spinning of any tests.

before (done) ->
  mongo.once 'ready', ->
    mongo.db.collection('api.users').drop()
    mongo.db.collection('api.users').insert data.api.users, (err) ->
      throw err if err
      done()

before (done) ->
  mongo.bilder.drop()
  mongo.grupper.drop()
  mongo.områder.drop()

  async.series [
    mongo.bilder.insert.bind(mongo.bilder, data.bilder)
    mongo.grupper.insert.bind(mongo.grupper, data.grupper)
    mongo.områder.insert.bind(mongo.områder, data.områder)
  ], done

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
  ], done

describe 'Unit Test', ->
  require './unit'

describe 'Integration Test', ->
  require './integration'

describe 'Acceptance Test', ->
  require './acceptance'

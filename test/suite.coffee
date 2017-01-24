async     = require 'async'

ObjectID  = require('mongodb').ObjectID
mongo     = require '@turbasen/db-mongo'
redis     = require '@turbasen/db-redis'

data          = require '@turbasen/test-data'
data.bilder   = require './data/bilder.json'
data.grupper  = require './data/grupper.json'
data.områder  = require './data/områder.json'
data.steder   = require './data/steder.json'
data.turer    = require './data/turer.json'

# Unset environment variable MONGO_URI to use test values for DB connection

process.env.MONGO_URI = undefined

# For some reason NodeJS or Mocha caches the object array but still tries to run
# the Object to ObjectID convertion. This results in new ObjectIDs for every run
# > 0. new ObjectID(ObjectID) => new ObjectId()

if not (data['steder'][0]._id instanceof ObjectID)
  data.api.users.push
    _id: new ObjectID '300000000000000000000000'
    provider: 'DNT'
    apps: [
      _id: new ObjectID '300000000000000000000001'
      name: 'dnt_app1'
      limit: test: 1000
      key: test: 'dnt'
      active: true
    ,
      _id: new ObjectID '300000000000000000000002'
      name: 'dnt_app2'
      limit: test: 500
      key: test: 'abc'
      active: true
    ]

  data.api.users.push
    _id: new ObjectID '400000000000000000000000'
    provider: 'NRK'
    apps: [
      _id: new ObjectID '400000000000000000000001'
      name: 'nrk_app1'
      limit: test: 1000
      key: test: 'nrk'
      active: true
    ]

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
  return done() if mongo.db
  return mongo.once 'ready', done

before (done) ->
  mongo.db.collection('api.users').drop()
  mongo.db.collection('api.users').insert data.api.users, (err) ->
    throw err if err
    done()

before (done) ->
  @timeout 10000

  mongo.bilder.drop()
  mongo.grupper.drop()
  mongo.områder.drop()

  async.parallel [
    mongo.bilder.insert.bind(mongo.bilder, data.bilder)
    mongo.grupper.insert.bind(mongo.grupper, data.grupper)
    mongo.områder.insert.bind(mongo.områder, data.områder)
  ], done

# Flush cache- and persistand data from Redis and MongoDB.

afterEach (done) ->
  mongo.steder.drop(null, done)

afterEach (done) ->
  mongo.turer.drop(null, done)

beforeEach (done) ->
  redis.flushall()

  async.series [
    mongo.steder.ensureIndex.bind(mongo.steder, { geojson: '2dsphere' })
    mongo.turer.ensureIndex.bind(mongo.turer, { geojson: '2dsphere' })
    mongo.steder.insert.bind(mongo.steder, data.steder)
    mongo.turer.insert.bind(mongo.turer, data.turer)
  ], done

describe 'Unit Test', ->
  require './unit'

describe 'Integration Test', ->
  require './integration'

describe 'Acceptance Test', ->
  require './acceptance'

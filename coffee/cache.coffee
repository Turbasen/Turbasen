"use strict"

MongoClient  = require('mongodb').MongoClient
redisClient  = require('redis').createClient
EventEmitter = require('events').EventEmitter
ObjectID     = require('mongodb').ObjectID
crypto       = require('crypto')

mongoUri     = process.env.MONGO_URI or 'mongodb://localhost:27017/test'
redisPort    = process.env.DOTCLOUD_CACHE_REDIS_PORT or 6379
redisHost    = process.env.DOTCLOUD_CACHE_REDIS_HOST or 'localhost'
redisPass    = process.env.DOTCLOUD_CACHE_REDIS_PASSWORD or null

redis        = redisClient redisPort, redisHost, auth_pass: redisPass
events       = new EventEmitter()
mongo        = null

MongoClient.connect mongoUri, (err, db) ->
  throw err if err
  mongo = db
  events.emit('ready', db)

cols = {}

dataFields =
  default:
    _id       : false
    tilbyder  : true
    endret    : true
    status    : true
    navn      : true
    bilder    : true
    grupper   : true

  bilder:
    _id       : false
    tilbyder  : true
    endret    : true
    status    : true
    navn      : true

dataTypes = [
  'arrangementer'
  'bilder'
  'grupper'
  'områder'
  'steder'
  'turer'
]

#
# Generate hash of object
#
# param {code object} data - data to generate checksum for
# param {code string} algo - hash algorithm to use (default md5)
#
# return {code string} md5 checksum
#
hash = (data, id) ->
  if id
    copy = _id: id
    copy[key] = val for key, val of data
    data = copy

  crypto.createHash('md5').update(JSON.stringify(data)).digest("hex")

#
# Get data filter for type
#
# param type - {code string} data type
# param preventDefault - {code boolean} prevent default filter
#
# return {code object} with <key>: <true|false>
#
getFilter = (type, preventDefault) ->
  return dataFields[type] if dataFields[type]
  return {} if preventDefault
  return dataFields.default

#
# Filter data according to type
#
# param type - {code string} data type
# param data - {code object} data to filter
#
# return {code data} filtered data (keys <= data.keys)
#
filter = (type, data) ->
  res = {}
  res[key] = data[key] for key,val of getFilter(type) when val is true and data[key]
  return res

#
# Get db collection connection
#
# col - {code string} collection name
# cb - {code function} callback function (err, col)
#
col = (col) ->
  cols[col] = mongo.collection col if not cols[col]
  cols[col]

#
# Get document from database for type and id
#
# param type - {code string) data type
# param id - {code string} item id
# param cb - {code function} callback function (err, data)
#
doc = (type, id, cb) ->
  col(type).findOne {_id: new ObjectID(id)}, getFilter(type), cb

#
# Store data in cache for data type and id
#
# param type - {code string) data type
# param id - {code string} item id
# param data - {code object} data to store
# param cb - {code function} callback function (err, msg)
#
set = (type, id, data, cb) ->
  if type in dataTypes
    data = filter type, data
    data.checksum = hash data, id
  redis.hmset "#{type}:#{id}", data, (err) -> cb(err, data)

#
# Get data from cache for type and id
#
# This function will return Arrays if data is retrived directly from the database.
# Data from the redis cache will be comma seperated strings in stead of arrays.
#
# param type - {code string) data type
# param id - {code string} item id
# param cb - {code function} callback function (err, data, hit)
#
get = (type, id, cb) ->
  redis.hgetall "#{type}:#{id}", (err, data) ->
    return cb null, data, true if data
    return cb null, null, false if type not in dataTypes

    doc type, id, (err, data) ->
      return cb err if err

      data = status: 'Slettet', endret: new Date().toISOString() if not data

      set type, id, data, (err, data) ->
        cb err, data, false

module.exports =
  events: events

  mongo: -> mongo
  redis: -> redis

  hash  : hash
  col   : col
  doc   : doc
  set   : set
  get   : get

  _getCols : -> cols
  _setCols : (c) -> cols = c; cols

  _dataTypes: -> dataTypes
  _dataFields: -> dataFields

  _getFilter: getFilter
  _filter: filter


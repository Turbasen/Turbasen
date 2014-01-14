"use strict"

redisClient = require('redis').createClient
ObjectID = require('mongodb').ObjectID

Cache = (mongo, port, host, pass) ->
  @mongo = mongo

  port ?= 6379
  host ?= 'localhost'
  pass ?= null

  @redis = redisClient port, host, auth_pass: pass
  @cols  = []

  @dataFields =
    default:
      _id       : false
      tilbyder  : true
      endret    : true
      checksum  : true
      status    : true
      navn      : true
      bilder    : true
      grupper   : true

    bilder:
      _id       : false
      tilbyder  : true
      endret    : true
      checksum  : true
      status    : true
      navn      : true

  @dataTypes = [
    'arrangementer'
    'bilder'
    'grupper'
    'områder'
    'steder'
    'turer'
  ]

  @

#
# Get data filter for type
#
# @param type - {@code string} data type
# @param preventDefault - {@code boolean} prevent default filter
#
# @return {@code object} with <key>: <true|false>
#
Cache.prototype.getFilter = (type, preventDefault) ->
  return @dataFields[type] if @dataFields[type]
  return {} if preventDefault
  return @dataFields.default

#
# Filter data according to type
#
# @param type - {@code string} data type
# @param data - {@code object} data to filter
#
# @return {@code data} filtered data (keys <= data.keys)
#
# @TODO what to do about undefined values
#
Cache.prototype.filterData = (type, data) ->
  res = {}
  res[key] = data[key] for key,val of @getFilter(type) when val is true and data[key]
  return res

#
# Get db collection connection
#
# @col - {@code string} collection name
# @cb - {@code function} callback function (err, col)
#
Cache.prototype.getCol = (col) ->
  @cols[col] = @mongo.collection col if not @cols[col]
  @cols[col]

#
# Get document from database for type and id
#
# This method will automaticly filter object keys according to type in order
# to prevent fetching of uncesserary data.
#
# @param type - {@code string) data type
# @param id - {@code string} item id
# @param cb - {@code function} callback function (err, data)
#
Cache.prototype.getDoc = (type, id, cb) ->
  @getCol(type).findOne {_id: new ObjectID(id)}, @getFilter(type), cb

#
# Store data in cache for data type and id
#
# @param type - {@code string) data type
# @param id - {@code string} item id
# @param data - {@code object} data to store
# @param cb - {@code function} callback function (err, msg)
#
Cache.prototype.set = (type, id, data, cb) ->
  if type in @dataTypes
    data = @filterData type, data
    data.checksum = @hash data, id
  @redis.hmset "#{type}:#{id}", data, (err) -> cb(err, data)

#
# Get data from cache for type and id
#
# This function will return Arrays if data is retrived directly from the database.
# Data from the redis cache will be comma seperated strings in stead of arrays.
#
# @param type - {@code string) data type
# @param id - {@code string} item id
# @param cb - {@code function} callback function (err, data, hit)
#
Cache.prototype.get = (type, id, cb) ->
  @redis.hgetall "#{type}:#{id}", (err, data) =>
    return cb null, data, true if data
    return cb null, null, false if type not in @dataTypes

    @getDoc type, id, (err, data) =>
      return cb err if err

      data = status: 'Slettet', endret: new Date().toISOString() if not data

      @set type, id, data, (err, data) =>
        cb err, data, false

module.exports = Cache


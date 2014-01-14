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
# Store data in cache for key
#
# @param key - {@code string} cache key
# @param data - {@code object} data to store
# @param cb - {@code function} callback function (err, msg)
#
Cache.prototype.set = (key, data, cb) ->
  @redis.hmset key, data, (err) -> cb(err, data)

#
# Get Data from cache for key
#
# @param key - {@code string} cache key
# @param cb - {@code function} callback function (err, msg)
#
Cache.prototype.get = (key, cb) ->
  @redis.hgetall key, cb

#
# Store data in cache for data type and id
#
# This function will automaticly remove object properties from input data in
# order to match the data type cache preferences defined in @getFilter().
#
# @param type - {@code string) data type @param id - {@code string} item id
# @param data - {@code object} data to store @param cb - {@code function}
# callback function (err, msg)
#
Cache.prototype.setForType = (type, id, data, cb) ->
  @set "#{type}:#{id}", @filterData(type, data), cb

#
# Get data from cache for type and id
#
# This function will return Arrays if data is retrived directly from the
# database.  Data from the redis cache will be comma seperated strings in
# stead of arrays.
#
# @param type - {@code string) data type @param id - {@code string} item id
# @param cb - {@code function} callback function (err, data, hit)
#
Cache.prototype.getForType = (type, id, cb) ->
  @get "#{type}:#{id}", (err, data) =>
    return cb null, data, true if data

    @getDoc type, id, (err, data) =>
      return cb err, null, false if err

      data = status: 'Slettet' if not data

      # We don't need to use @setForType() here since data is already formated
      # when using @getDoc()

      @set "#{type}:#{id}", data, (err, data) =>
        cb err, data, false

module.exports = Cache


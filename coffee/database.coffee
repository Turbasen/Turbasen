#
# Nasjonal Turbase v1
#
# Database connection wrapper
#
# @author Hans Kristian Flaatten
#

"use strict"

MongoClient = require('mongodb').MongoClient
ObjectId    = require('mongodb').ObjectId
events      = require 'events'
util        = require 'util'

collections = {}

#
# Constructor
#
Database = (uri, cb) ->
  events.EventEmitter.call @

  @uri  = uri
  @db   = null
  @cols = {}

  @_openDatabase cb if typeof cb is 'function'

  @

# Initiate event emmitting 
util.inherits Database, events.EventEmitter

#
# Open database connection
#
# @TODO add optional callback?
#
Database.prototype.open = ->
  $this = @
  @_openDatabase (err, db) ->
    return $this.emit 'error', err if err
    return $this.emit 'ready', db

#
# Close database connection
#
Database.prototype.close = (cb) ->
  return cb() if @db is null
  return @db.close cb

#
# Open database connection
#
# @param cb - {@code function} callback method (err, db)
#
Database.prototype._openDatabase = (cb) ->
  $this = @
  MongoClient.connect @uri, (err, db) ->
    return cb err if err
    $this.db = db
    return cb null, db

#
# Get database instance
#
# return {@code MongoDB}
#
Database.prototype.getDatabase = ->
  return @db

#
# Get collection pointer
#
# Get a database pointer to a given collection
#
# @param collection - {@code string} collection name
# @param cb - {@code function} callback function (err, collection)
#
Database.prototype.getCollection = (collection, cb) ->
  if @cols[collection]
    return cb null, @cols[collection]
  else if @cols[collection] is null
    err = new Error 'CollectionDoesNotExist'
    @emit 'error', err
    return cb err
  else
    $this = @
    @db.collection collection, (err, coll) ->
      if err
        $this.cols[collection] = null
        $this.emit 'error', err
        return cb err
      
      $this.cols[collection] = coll
      return cb null, coll

#
# Parse projection fields
#
Database.prototype._parseFields = (fields) ->
  return {} if not fields

  returnFields = {}

  if fields.include and fields.include instanceof Array
    for field in fields.include
      returnFields[field] = true

  if fields.exclude and fields.include instanceof Array
    for field in fields.exclude
      returnFields[field] = false

  return returnFields

#
# Get matching documents from collection
#
# @param col - {@code object} collection instance
# @param opts - {@code object} parameter
# @param cb - {@code function} callback function
#
Database.prototype.getDocuments = (col, opts, cb) ->
  query   = opts.query || {}
  fields  = @_parseFields opts.fields
  options =
    limit : opts.limit || 10
    skip  : opts.skip  || 0
    sort  : opts.sort

  col.find(query,fields,options).toArray cb

#
# Get document for ID
#
Database.prototype.getDocument = (col, id, cb) ->
  col.findOne _id: id, cb

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
Database.prototype.each = (cursor, fn, done) ->
  next = (i, count) ->
    return done null, --i, count if i is count
    cursor.nextObject (err, doc) ->
      return done err, i, count if err
      return done null, i, count if doc is null
      fn doc, i, count, (err) ->
        return done err, i, count if err
        next(++i, count)

  cursor.count (err, count) ->
    count = cursor.limitValue || count if count isnt 0
    return done err, 0, count if err or count is 0
    next 0, count

# Export class
module.exports = Database


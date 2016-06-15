    ObjectID  = require('mongodb').ObjectID

Import event emitter stuff.

    EventEmitter = require('events').EventEmitter
    inherits = require('util').inherits

Import data storage modules.

    mongo   = require '../db/mongo'
    redis   = require '../db/redis'

    parse   = require '../helper/parse'
    cache   = require '../helper/cache'

    collections = require('../helper/schema').types

## Class: Doc

### Params

* `string` type - document type
* `string` id - document id

### Return

New `Doc`.

    module.exports = Doc = (type, id) ->
      throw new Error('Missing Doc type param') if not type
      throw new Error('Missing or invalid ID param') if typeof id isnt 'string' and id isnt null

      EventEmitter.call @

      @db   = mongo[type]
      @id   = if typeof id is 'string' then new ObjectID(id) else null
      @type = type
      @data = {}
      @chit = false

      if @id
        redis.hgetall "#{@type}:#{@id.toString()}", (err, data) =>
          return @emit 'error', err if err

          if Object.keys(data).length
            @data = cache.arrayify @type, data
            @chit = true
            return @emit 'ready'

          @db.findOne _id: @id, cache.getFilter(@type), (err, data) =>
            return @emit 'error', err if err

            @data = data or status: 'Slettet'
            redis.hmset "#{@type}:#{@id}", @data, (err) =>
              return @emit 'ready'
      else
        process.nextTick => @emit 'ready'

      return @

    inherits Doc, EventEmitter

## Doc.exists

Check if document exists.

### Return

Returns `true` if document exists; otherwise `false`.

    Doc.prototype.exists = ->
      return @data.status? and @data.status isnt 'Slettet'


## Doc.getId

Get document id (ObjectID) for current document.

### Return

Returns an `ObjectID` if the document has an id; otherwise `null`.

    Doc.prototype.getId = ->
      @id


## Doc.wasCacheHit

Check if document request was a cache hit.

### Return

Returns `true` if document request was a cache hit; otherwise `false`.

    Doc.prototype.wasCacheHit = ->
      @chit


## Doc.isNotModifiedSince

Check if document has not been modified since a given timestamp.

### Params

* `string` time - timestamp to check against.

### Return

Returns `true` if document has not been modified since given tmestamp; otherwise
`false`.

    Doc.prototype.isModifiedSince = (time) -> @modifiedSince time, false
    Doc.prototype.isNotModifiedSince = (time) -> @modifiedSince time, true

    Doc.prototype.modifiedSince = (time, negate) ->
      return false if not time or not @data.endret

      if not isNaN time
        # Make unix timestamp into milliseconds
        time = time + '000' if (time + '').length is 10
        time = parseInt time

      org = new Date(@data.endret)
      chk = new Date(time)

      # HTTP-date's don't have milliseconds
      org.setMilliseconds(0)

      return false if chk.toString() is 'Invalid Date'

      return chk >= org if negate
      return chk <  org


## doc.isMatch

Check if checksum, or Etag, matche current document checksum.

### Params

* `string` checksum - checksum to check against.

### Return

Returns `true` if checksum matches the current checksum; otherwise `false`.

    Doc.prototype.isMatch = (checksum) ->
      return false if not checksum or not @data.checksum
      return (checksum is "\"#{@data.checksum}\"" or checksum is '*')


## doc.isNoneMatch

Check if checksum, or Etag, doesnt match current document checksum.

### Params

* `string` checksum - checksum to check against.

### Return

Return `true` if checksum does not match or document has no checksum; otherwise
`false`.

    Doc.prototype.isNoneMatch = (checksum) ->
      return false if not checksum
      return true if not @data.checksum
      return checksum isnt "\"#{@data.checksum}\""

## Doc.get

Get cached data for current document.

### Params

* `string` key - get specific object property

### Return

Returns an `object` if `key` is `undefined`; otherwise `string`. Will retur
`undefined` if the given key does not exist.

    Doc.prototype.get = (key) ->
      return @data if not key
      return @data[key]


## doc.getFull

### Params

* `object` filter - control which object properties are returned
* `function` cb - callback function (`Error` err, `object` data)

### Return

Returns `undefined`.

    Doc.prototype.getFull = (filter, cb) ->
      if not cb
        throw new Error('Document doesnt exists') if not @exists()
        return @db.find _id: @id, filter, limit: 1
      else
        return cb new Error('Document doesnt exists') if not @exists()
        @db.findOne _id: @id, filter, cb


## Doc.insert

Inserts a document into databse.

### Params

* `object` data - data to insert for document.
* `function` cb - callback function (`Error` err, `Array` warn, `object` data).

### Return

Returns `undefined`.

    Doc.prototype.insert = (data, cb) ->
      return cb new Error('Document already exists') if @exists()
      return cb new Error('Document is deleted') if @data.status is 'Slettet'

      parse.docInsert @type, data, (err, warn, data) =>
        return cb err if err

        @db.insertOne data, w: 1, (err) =>
          return cb err if err

          @id   = new ObjectID(data._id)
          @data = cache.filterData @type, data

          redis.hmset "#{@type}:#{@id.toString()}", @data

          cb err, warn, data


## Doc.replace

Replaces all document data in database.

### Params

* `object` data - replacement data for document.
* `function` cb - callback function (`Error` err, `Array` warn, `object` data).

### Return

Returns `undefined`.

    Doc.prototype.replace = (data, cb) ->
      return cb new Error('Document doesnt exists') if not @exists()

      parse.docReplace @type, data, (err, warn, data) =>
        return cb err if err

        @db.replaceOne _id: @id, data, w: 1, (err) =>
          return cb err if err

          @data = cache.filterData @type, data

          redis.del "#{@type}:#{@id.toString()}"
          redis.hmset "#{@type}:#{@id.toString()}", @data

          data._id = @id
          cb err, warn, data


## Doc.update

Partially update the document-data in database. This is some times refered to as
PATCH in a HTTP / REST context.

### Params

* `object` data - replacement object for document.
* `function` cb - callback function (`Error` err, `Array` warn, `object` data).

### Return

Returns `undefined`.

    Doc.prototype.update = (query, cb) ->
      return cb new Error('Document doesnt exists') if not @exists()

      parse.docPatch @type, query, (err, warn, query) =>
        return cb err if err

        @db.updateOne _id: @id, query, w: 1, (err) =>
          return cb err if err

          @getFull {}, (err, doc) =>
            @data = cache.filterData @type, doc

            redis.del "#{@type}:#{@id.toString()}"
            redis.hmset "#{@type}:#{@id.toString()}", @data

            cb err, warn, doc


## Doc.delete

Delete a document from the database by removing all document properties and
setting the `status` property to `Slettet`.

### Params

* `function`  cb - callback function (`Error` err).

### Return

Returns `undefined`.

    Doc.prototype.delete = (cb) ->
      return cb new Error('Document doesnt exists') if not @exists()

      @data = status: 'Slettet', endret: new Date()
      @db.replaceOne _id: @id, @data, w: 1, (err) =>
        return cb err if err

        redis.del "#{@type}:#{@id.toString()}"
        redis.hmset "#{@type}:#{@id.toString()}", @data

        cb null


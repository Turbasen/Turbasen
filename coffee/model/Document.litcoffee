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

---

## Class: Doc

### new Doc(type, id)

* **string** `type` - document type (collection name)
* **string** `id` - document id

---

    module.exports = Doc = (type, id) ->
      throw new Error('Missing Doc type param') if not type
      throw new Error('Missing or invalid ID param') if typeof id isnt 'string' and id isnt null

      EventEmitter.call @

### doc.db

MongoDB collection instance where the document is stored.

      @db   = mongo[type]

### doc.id

Unique `ObjectID` for the document. Access through `doc.getId()`.

      @id   = if typeof id is 'string' then new ObjectID(id) else null

### doc.type

Document collection name (object type).

      @type = type

### doc.data

Cached document data from Redis. This gets poppulated automaticly when the
a new document is instanciated.

      @data = {}

### doc.chit

Cache hit indicator. Accessed through `doc.wasCacheHit()`.

      @chit = false

---

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

### doc.exists()

Check if document exists. Returns `true` if document exists; otherwise `false`.

---

    Doc.prototype.exists = ->
      return @data.status? and @data.status isnt 'Slettet'


### doc.getId()

Get the unique id for current document. Returns an `ObjectID` if the document
exists; otherwise `null`.

---

    Doc.prototype.getId = ->
      @id


### doc.wasCacheHit()

Check if document request was a cache hit. Returns `true` if document request
was a cache hit; otherwise `false`.

---

    Doc.prototype.wasCacheHit = ->
      @chit


### doc.isNotModifiedSince(time)

* **string** `time` - timestamp to check against.

Check if document has not been modified since a given timestamp. Returns `true`
if document has not been modified since given timestamp; otherwise `false`.

---

    Doc.prototype.isModifiedSince = (time) -> @modifiedSince time, false
    Doc.prototype.isNotModifiedSince = (time) -> @modifiedSince time, true

    Doc.prototype.modifiedSince = (time, negate) ->
      return false if not time or not @data.endret

      if not isNaN time
        # Make UNIX timestamp into milliseconds
        time = time + '000' if (time + '').length is 10
        time = parseInt time

      org = new Date(@data.endret)
      chk = new Date(time)

      # HTTP-date's don't have milliseconds
      org.setMilliseconds(0)

      return false if chk.toString() is 'Invalid Date'

      return chk >= org if negate
      return chk <  org


### doc.isMatch(checksum)

* **string** `checksum` - checksum to check against.

Check if checksum, or Etag, matches current document checksum. Returns `true`
if checksum matches the current checksum; otherwise `false`.

---

    Doc.prototype.isMatch = (checksum) ->
      return false if not checksum or not @data.checksum
      return (checksum is "\"#{@data.checksum}\"" or checksum is '*')


### doc.isNoneMatch(checksum)

* **string** `checksum` - checksum to check against.

Check if checksum, or Etag, doesn't match current document checksum. Return
`true` if checksum does not match or document has no checksum; otherwise
`false`.

---

    Doc.prototype.isNoneMatch = (checksum) ->
      return false if not checksum
      return true if not @data.checksum
      return checksum isnt "\"#{@data.checksum}\""

### doc.get([key])

* **string** `key` - get specific object property

Get cached data for the current document. Returns an `object` if `key` is
`undefined`; otherwise `string`. Will return `undefined` if the given key does
not exist.

---

    Doc.prototype.get = (key) ->
      return @data if not key
      return @data[key]


### doc.getFull(filter[, cb])

* **object** `filter` - control which object properties are returned
* **function** `cb` - callback function (**Error** `err`, **object** `data`)

Get the full document data from the database asynchronously. Returns a cursor
stream if `cb` is undefined.

---

    Doc.prototype.getFull = (filter, cb) ->
      if not cb
        throw new Error('Document doesnt exists') if not @exists()
        return @db.find _id: @id, filter, limit: 1
      else
        return cb new Error('Document doesnt exists') if not @exists()
        @db.findOne _id: @id, filter, cb


### doc.getExpanded(filter, expand, query, cb)

* **object** `filter` - control which object properties are returned
* **array** `expand` - sub-document property names to expand
* **object** `query` - query for expanded sub-documents
* **function** `cb` - callback function (**Error** `err`, **object** `data`)

Get the full document with expanded sub-documents from the database
asynchronously. To expand a given collection jsut pass the collection name to
the `expand` parameter and it will be merged with the document data.

---

    Doc.prototype.getExpanded = (filter, expand, query, cb) ->
      return cb new Error('Document doesnt exists') if not @exists()

      count = 0
      mapped = {}

Since `expand` might be a user supplied input parameter we need to limit it to
properties which are expandable (`collections`). We also remove properties which
holds no value for this document.

      expand = expand
        .filter (v) => @data[v] and v in collections

Next we map the string array into an object array on the following format:
`{ type: String, ids: Array }` where `ids` are ObjectIDs to an document of the
collection `type`.

        .map (v) => type: v, ids: @data[v].map (d) -> new ObjectID d

Set up a `final` function which is called when expanded data is ready to be
mapped to the original document.

      final = () =>
        @db.findOne _id: @id, filter, (err, doc) ->
          cb err, Object.assign doc or {}, mapped

If there are no fields to expand, we just call the `final` function instantly
and no fields will get expanded.

      return final() if expand.length is 0

Set up a `next` function which is called for each expanded data returned from
the database. Expanded data is stored in the `mapped` object which is merged
with the main document in `final`. When all expanded fields are mapped `final`
is called.

      next = (type, _, docs) ->
        mapped[type] = docs or []
        return final() if Object.keys(mapped).length == expand.length

Get the expanded sub-documents from the database.

      expand.forEach (x) ->
        mongo[x.type]

We find the sub-documents using the ObjectIDs in the expanded fields, that is
the easy part. The tricky part is to prevent information leakage of private
documents. This the second part is a `query` limiting the results to public
documents or those owned by the current API user.

          .find Object.assign {_id: $in: x.ids}, query

We reuse the projection filter from the original document, but since we do not
know in advanced who owns a given sub-document we remove the `private` property
to prevent information leakage.

          .project Object.assign filter, privat: false

Bundle all the sub-documents in one array and pass it to the `next` function.

          .toArray next.bind null, x.type


### doc.insert(data, cb)

* **object** `data` - data to insert for document.
* **function** `cb` - callback function (**Error** `err`, **Array** `warn`, **object** `data`).

Inserts a new document into database.

---

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


### doc.replace(data, cb)

* **object** `data` - replacement data for document.
* **function** `cb` - callback function (**Error** `err`, **Array** `warn`, **object** `data`).

Replaces all document data in database.


---

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


### doc.update(data, cb)

* **object** `data` - replacement object for document.
* **function** `cb` - callback function (**Error** `err`, **Array** `warn`, **object** `data`).

Partially update the document-data in database. This is some times referred to as
PATCH in a HTTP / REST context.

---

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


### doc.delete(cb)

* **function** `cb` - callback function (**Error** `err`).

Delete a document from the database by removing all document properties and
setting the `status` property to `Slettet`.

---

    Doc.prototype.delete = (cb) ->
      return cb new Error('Document doesnt exists') if not @exists()

      @data = status: 'Slettet', endret: new Date()
      @db.replaceOne _id: @id, @data, w: 1, (err) =>
        return cb err if err

        redis.del "#{@type}:#{@id.toString()}"
        redis.hmset "#{@type}:#{@id.toString()}", @data

        cb null

    ObjectID  = require('mongodb').ObjectID
    joi       = require 'joi'

    rand = require('crypto').pseudoRandomBytes
    hash = require('crypto').createHash

    schema  = require '../helper/schema'

## docDefault()

Set default document data properties.

### Params

* `string` type - data type for document
* `object` data - data to parse for document
* `boolean` isPatch - if this is a part of a patch

### Return

Returns an `Array` with two items `Array` warnings and `object` data.

    exports.docDefaults = (type, data, isPatch) ->
      warn = []

      data.endret = new Date().toISOString()
      data.checksum = hash('sha1').update(rand(128)).digest('hex')

      # Don't set these fields if this is a patch
      if not isPatch
        if not data.lisens
          data.lisens = 'CC BY 4.0'
          warn.push resource: 'Document', field: 'lisens', code: 'missing_field'

        if not data.navngiving
          warn.push resource: 'Document', field: 'navngiving', code: 'missing_field'

        if not data.status
          data.status = 'Kladd'
          warn.push resource: 'Document', field: 'status', code: 'missing_field'

      [warn, data]

## docValidate()

Validate document data against required, optional and type-specific data
schemas.

### Params

* `string` type - data type for document
* `object` data - data to parse for document
* `functions` cb - callback function (`Error` err, `Array` warn, `object` data)

### Retrun

Returns `undefined`.

    exports.docValidate = (type, data, cb) ->
      opt = allowUnknown: true, abortEarly: false

      joi.validate data, schema.required, opt, (err) ->
        return cb err if err
        joi.validate data, schema.optional, opt, (err) ->
          return cb err if err
          joi.validate data, schema.type[type], opt, cb

## docInsert()

Parse document data in an insert context.

### Params

* `string` type - data type for document
* `object` data - data to parse for document
* `functions` cb - callback function (`Error` err, `Array` warn, `object` data)

### Retrun

Returns `undefined`.

    exports.docInsert = (type, data, cb) ->
      data._id = new ObjectID().toString() if not data._id
      [warn, data] = exports.docDefaults type, data, false

      exports.docValidate type, data, (err) ->
        data._id = new ObjectID(data._id)
        cb err, warn, data

## docReplace()

Parse document data in an replace context.

### Params

* `string` type - data type for document
* `object` data - data to parse for document
* `functions` cb - callback function (`Error` err, `Array` warn, `object` data)

### Retrun

Returns `undefined`.

    exports.docReplace = (type, data, cb) ->
      delete data._id
      [warn, data] = exports.docDefaults type, data, false

      exports.docValidate type, data, (err) ->
        cb err, warn, data

## docPatch()

Parse document data in an patch context.

### Params

* `string` type - data type for document
* `object` data - data to parse for document
* `functions` cb - callback function (`Error` err, `Array` warn, `object` data)

### Retrun

Returns `undefined`.

    exports.docPatch = (type, data, cb) ->
      orig = data
      data = $set: {}

Make sure we have no other root properties other than the opperations permitted.
If there are any move them into `data.$set` unless that is already specified. We
only allow a subset of the [update
operations](http://docs.mongodb.org/master/reference/operator/update/) permitted
by MongoDB.

      for key, val of orig
        if key[0] is '$'
          data[key] = val if key in ['$set', '$unset', '$push', '$pull']
        else if not orig.$set
          data.$set[key] = val

Remove some illegal operations such as `$set`ing read only values, or doing
other operations on required document properties.

      for key in Object.keys data
        delete data[key]._id
        delete data[key].tilbyder
        delete data[key].endret
        delete data[key].checksum

        if key isnt '$set'
          delete data[key].lisens
          delete data[key].navngiving
          delete data[key].status

      [warn, data.$set] = exports.docDefaults type, data.$set, true

      exports.docValidate type, data.$set, (err) ->
        cb err, warn, data


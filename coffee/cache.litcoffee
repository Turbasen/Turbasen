    "use strict"

## getFilter()

Get data filter for object type.

### Params

* `String` type - object type to get filter for.
* `boolean` preventDefault - prevent default filter switch.

### Return

Returns a `String` key - `boolean` value `Object` where each key represent a
document field. The value determines if they field should be included or not.

Returns an empty `Object` if the `preventDefault` parameter is set to `true` and
no filter was found for the given `type`.


    getFilter = (type, preventDefault) ->

      dataFields =
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

      return dataFields[type] if dataFields[type]
      return {} if preventDefault
      return dataFields.default


## filterData()

Filter data for given type.

### ToDo

* Handle undefined values.

### Params

* `String` type - object type to filter data for.
* `Object` data - data to filter on.

### Return

Returns an `Object` with a subset of the original object containing only the
accepted object properties for the given object type.

    filterData = (type, data) ->
      res = {}
      res[key] = data[key] for key,val of getFilter(type) when val is true and data[key]
      return res


## getDoc()

Get a document from MongoDB for given object type and object id.

This function will automaticly filter object keys according to type in order to
prevent fetching of uncesserary data.

### Params

* `String` type - object type to get document for.
* `String` id - object id for document.
* `function` cb - callback function (`Error` err, `Object` doc).

### Return

No return value or `undefined`.


    getDoc = (type, id, cb) ->
      ObjectID = require('mongodb').ObjectID
      require('./db/mongo')[type].findOne {_id: new ObjectID(id)}, getFilter(type), cb


## set()

Store data object in Redis for a given cache key.

### Params

* `String` key - cache key to store data for.
* `Object` data - data to store for cache key.
* `function` cb - callback function (`Error` err, `Object` data).

### Return

No return value or `undefined`.


    set = (key, data, cb) ->
      require('./db/redis').hmset key, data, (err) -> cb(err, data)


## get()

Retrive data from cache for given a cache key.

### Params

* `String` key - cache key to get data for.
* `function` cb - callback function (`Error` err, `Object` data).

### Return

No return value or `undefined`.


    get = (key, cb) ->
      require('./db/redis').hgetall key, cb


## setForType()

Store data in Redis for given object type and object id.

This function will automaticly remove object properties from input data in order
to match the object type cache preferences as defined in [#getFilter()](#getFilter).

### Params

* `String` type - object type to set cache data for.
* `String` id - object id to set cache data for.
* `Object` data - data store in cache for type and id.
* `function` cb - callback function (`Error` err, `Object` data).

### Return

No return value or `undefined`.


    setForType = (type, id, data, cb) ->
      set "#{type}:#{id}", filterData(type, data), cb


## getForType()

Get data from Redis for object type and object id.

`NB` This function will return `Arrays` if the document is retrived directly
from MongoDB. `Arrays` stored in Redis will be returned as comma seperated
strings.

### Params

* `String` type - object type to get cache data for.
* `String` id - object id to get cache data for.
* `function` cb - callback function (`Error` err, `Object` data).

### Return

No return value or `undefined`.


    getForType = (type, id, cb) ->
      get "#{type}:#{id}", (err, data) ->
        return cb null, data, true if data

        getDoc type, id, (err, data) ->
          return cb err, null, false if err

          data = status: 'Slettet' if not data

          # We don't need to use setForType() here since data is already formated
          # when using getDoc()

          set "#{type}:#{id}", data, (err, data) ->
            cb err, data, false


## Export

Expose the functions we want to be public by exporting them.


    module.exports =
      set       : set
      get       : get
      getDoc    : getDoc
      setForType: setForType
      getFilter : getFilter
      filterData: filterData
      getForType: getForType


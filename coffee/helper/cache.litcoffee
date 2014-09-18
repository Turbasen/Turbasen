
## getFilter()

Get data filter to use in caching.

### Params

* `string` type - object type to get filter for

### Return

Returns an `object` with `field` and filter status (`boolean`).

    exports.getFilter = (type) ->
      {
        _id       : false
        tilbyder  : true
        endret    : true
        checksum  : true
        status    : true
        navn      : true
        områder   : true
        steder    : true
        bilder    : true
        grupper   : true
      }


## filterData()

Filter raw data before storing it in cache.

### Params

* `string` type - object type
* `object` data - data to filter

### Return

Returns an `object` with correct data fields.

    exports.filterData = (type, data) ->
      ret = {}
      ret[key] = data[key] for key, val of exports.getFilter(type) when val and data[key]
      ret


## arrayify()

Make certain string values in data structure into arrays.

### Params

* `string` type - object type
* `object` data - data to arrayify

### ToDo

* [] Make this not hard coded

### Return

Returns an `object` with correct fields as arrays.

    exports.arrayify = (type, data) ->
      data.områder = if data.områder then data.områder.split(',') else []
      data.grupper = if data.grupper then data.grupper.split(',') else []
      data.bilder  = if data.bilder  then data.bilder.split(',')  else []
      data.steder  = if data.steder  then data.steder.split(',')  else []

      return data


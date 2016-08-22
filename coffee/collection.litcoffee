    MongoQS     = require 'mongo-querystring'
    Document    = require './model/Document'
    stringify   = require('JSONStream').stringify

    collections = require('./helper/schema').types
    sentry      = require './db/sentry'
    mongo       = require '@turbasen/db-mongo'

    qs = new MongoQS
      alias:
        tag: 'tags.0'
        gruppe: 'grupper'
        endret: 'after'
        order: 'sort'
      blacklist:
        api_key     : true # other use
        sort        : true # other use
        limit       : true # other use
        skip        : true # other use
        fields      : true # other use
        _id         : true # use API endpoint
      custom:
        bbox: 'geojson'
        near: 'geojson'
        after: 'endret'

## PARAM {collection}

    exports.param = (req, res, next, col) ->
      col = decodeURIComponent col

      if col not in collections
        return res.status(404).json message: "Type #{col} not found"

      req.type = col
      req.db   = col: mongo[col], query: {}

      next()

    exports.paramCol2 = (req, res, next, col2) ->
      if col not in collections
        return res.status(404).json message: "Type #{col2} not found"

      req.type      = col2
      req.db.col    = mongo[col2]
      req.db.query  = [{status: 'Offentlig'}, {tilbyder: req.user.provider}]

      next()


## HEAD /{collection}
## GET /{collection}

    exports.get = (req, res, next) ->

### Query

      req.db.query = req.user.query qs.parse req.query

### Fields

Always return `endret`, `lisens`, `navn`, `status`, `tilbyder`, and `tags` in
addition to `\_id` ObjectID which is always returned by MongoDB.

      fields =
        endret: true
        lisens: true
        navn: true
        status: true
        tags: true
        tilbyder: true

Parse user specified fields to be returned.

      if typeof req.query.fields is 'string' and req.query.fields
        for field in req.query.fields.split ','
          fields[field] = true

If any private fields are to be returned we need to limit the query to documents
owner by the API user to prevent exposing private data publicly.

          req.db.query.tilbyder = req.user.provider if field.substr(0,6) is 'privat'

### Sort

Limit sort to ascending or descending on `\_id`, `endret`, and `navn` since they
are indexed. Non-indexed fields will be slower. Also, don't allow ordering of
geospatial queries to prevent performance bottlenecks. From the [MongoDB
refference](http://docs.mongodb.org/manual/reference/operator/query/near/#behavior):

> $near always returns the documents sorted by distance. Any other sort order
> requires to sort the documents in memory, which can be inefficient.

      if not req.db.query.geojson
        sort = switch req.query.sort
          when '_id' then [['_id', 1]]
          when '-_id' then [['_id', -1]]
          when 'endret' then [['endret', 1]]
          when '-endret' then [['endret', -1]]
          when 'navn' then [['navn', 1]]
          when '-navn' then [['navn', -1]]
          else 'endret'

### Execute

Make new cursor object with the correct query, fields, and other options (limit,
skip, and sort).

      cursor = req.db.col.find req.db.query, fields,
        limit: Math.min (parseInt(req.query.limit, 10) or 20), 50
        skip: parseInt(req.query.skip, 10) or 0
        sort: sort

Count number of matching documents in MongoDB database. Ignore limit and skip
settings by passing `false` as the first argument to `cursor.count()`.

      cursor.count false, (err, total) ->
        return next err if err

Calculate the total number of documents that will eventually be returned (not
the total number of matching documents) since we don't know that in advanced
(due to the nature of streaming).

        count = Math.min cursor.cmd.limit, Math.max total - cursor.cmd.skip, 0

Set `Count-Return` and `Count-Total` headers so that one can use a `HEAD` query
to look up the number of matched documents for a query without the documents
them selves. This may be useful for statistics purposes.

        res.set 'Count-Return', count
        res.set 'Count-Total', total

Return to the user if this is a `HEAD` query or there are no matching documents.

        return res.sendStatus 204 if req.method is 'HEAD'
        return res.json documents: [], count: 0, total: 0 if total is 0

Stream matching documents in order to prevent loading them into memory.

        res.set 'Content-Type', 'application/json; charset=utf-8'

        op = '{"documents":['
        cl = '],"count":' + count + ',"total":' + total + '}'

        cursor.stream().pipe(stringify(op, ',', cl)).pipe(res)

## POST /{collection}

    exports.post = (req, res, next) ->
      return res.status(400).json message: 'Body is missing' if Object.keys(req.body).length is 0
      return res.status(422).json message: 'Body should be a JSON Hash' if req.body instanceof Array

      req.body.tilbyder = req.user.provider

      new Document(req.type, null).once('error', next).once 'ready', ->
        @insert req.body, (err, warn, data) ->
          if err
            return next(err) if err.name isnt 'ValidationError'

            sentry.captureDocumentError req, err

            return res.status(422).json
              document: req.body
              message: 'Validation Failed'
              errors: err.details #TODO(starefossen) document this

          res.set 'ETag', "\"#{data.checksum}\""
          res.set 'Last-Modified', new Date(data.endret).toUTCString()
          # res.set 'Location', req.get 'host'

          return res.status(201).json
            document: data
            message: 'Validation Warnings' if warn.length > 0
            warnings: warn if warn.length > 0

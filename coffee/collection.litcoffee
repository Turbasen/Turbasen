    MongoQS     = require 'mongo-querystring'
    Document    = require './model/Document'
    stringify   = require('JSONStream').stringify

    sentry      = require './db/sentry'
    mongo       = require './db/mongo'

    collections = [
      'turer'
      'steder'
      'grupper'
      'områder'
      'bilder'
      'arrangementer'
    ]

    qs = new MongoQS
      alias:
        tag: 'tags.0'
        gruppe: 'grupper'
        endret: 'after'
      ignore:
        api_key     : true # other use
        order       : true # reserved
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
      if col not in ['turer', 'steder', 'grupper', 'områder', 'bilder', 'arrangementer']
        return res.json 404, message: 'Objekttype ikke funnet'

      req.type = col
      req.db   = col: mongo[col], query: {}

      next()

## OPTIONS /{collection}

    exports.options = (req, res, next) ->
      res.setHeader 'Access-Control-Expose-Headers', [
        'ETag', 'Location', 'Last-Modified', 'Count-Return', 'Count-Total'
      ].join(', ')
      res.setHeader 'Access-Control-Max-Age', 86400
      res.setHeader 'Access-Control-Allow-Headers', 'Content-Type'
      res.setHeader 'Access-Control-Allow-Methods', 'HEAD, GET, POST'
      res.send 204

## HEAD /{collection}
## GET /{collection}

    exports.get = (req, res, next) ->

### Query

      req.db.query = qs.parse req.query

Prevent private documents for other API user from being returned when quering
`tilbyder` and `status` fields.

      for key, val of req.query
        switch key
          when 'status'
            req.db.query.tilbyder = req.usr if val not in ['Offentlig', 'Slettet']
            break
          when 'tilbyder'
            req.db.query.status = 'Offentlig' if val isnt req.usr
            break
          else
            if key.substr(0,6) is 'privat'
              req.db.query.tilbyder = req.usr
              break

Apply default access control unless `status` or `tilbyder` fields are already
queried.

      if not req.db.query.tilbyder or req.db.query.status
        req.db.query.$or = [{status: 'Offentlig'}, {tilbyder: req.usr}]

### Fields

      if typeof req.query.fields is 'string' and req.query.fields
        fields = {}
        for field in req.query.fields.split ',' when field.substr(0,6) isnt 'privat'
          fields[field] = true

      else
        fields =
          tilbyder: true
          endret: true
          status: true
          lisens: true
          navn: true
          tags: true

### Sort

Limit sort to ascending or descending on `endret` and `navn` since they are
indexed, non-indexed fields could be slower.

      if typeof req.query.sort is 'string' and req.query.sort
        sort = switch req.query.sort
          when 'endret' then [['endret', 1]]
          when '-endret' then [['endret', -1]]
          when 'navn' then [['navn', 1]]
          when '-navn' then [['navn', -1]]
          else 'endret'

Only apply default sort if there are no geospatial queries.

      else
        sort = 'endret' if not req.db.query.geojson

### Execute

      options =
        limit: Math.min((parseInt(req.query.limit, 10) or 20), 50)
        skip: parseInt(req.query.skip, 10) or 0
        sort: sort

Retrive matching documents from MongoDB.

      cursor = req.db.col.find(req.db.query, fields, options)
      cursor.count (err, total) ->
        return next err if err
        res.set 'Count-Return', Math.min(options.limit, total)
        res.set 'Count-Total', total
        return res.send 204 if req.method is 'HEAD'
        return res.json documents: [], count: 0, total: 0 if total is 0
        res.set 'Content-Type', 'application/json; charset=utf-8'

Calculate number of rows returned since we don't know that in advanced (due to
the nature of streaming).

        count = Math.min(options.limit, Math.max(total - options.skip, 0))

Stream documents user in order to prevent loading them into memory.

        op = '{"documents":['
        cl = '],"count":' + count + ',"total":' + total + '}'

        cursor.stream().pipe(stringify(op, ',', cl)).pipe(res)

## POST /{collection}

    exports.post = (req, res, next) ->
      return res.json 400, message: 'Body is missing' if Object.keys(req.body).length is 0
      return res.json 422, message: 'Body should be a JSON Hash' if req.body instanceof Array

      req.body.tilbyder = req.usr

      new Document(req.type, null).once('error', next).once 'ready', ->
        @insert req.body, (err, warn, data) ->
          if err
            return next(err) if err.name isnt 'ValidationError'

            sentry.captureDocumentError req, err

            return res.json 422,
              document: req.body
              message: 'Validation Failed'
              errors: err.details #TODO(starefossen) document this

          res.set 'ETag', "\"#{data.checksum}\""
          res.set 'Last-Modified', new Date(data.endret).toUTCString()
          # res.set 'Location', req.get 'host'

          return res.json 201,
            document: data
            message: 'Validation Warnings' if warn.length > 0
            warnings: warn if warn.length > 0


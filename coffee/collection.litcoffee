    ObjectID    = require('mongodb').ObjectID
    stringify   = require('JSONStream').stringify

    Document    = require './model/Document'

    sentry      = require './db/sentry'
    mongo       = require './db/mongo'

## PARAM {collection}

    exports.param = (req, res, next, col) ->
      if col not in ['turer', 'steder', 'grupper', 'områder', 'bilder', 'arrangementer']
        return res.json 404, message: 'Objekttype ikke funnet'

      req.type = col
      req.db   = col: mongo[col]

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
      query = {}

### ?tag=`String`

      if typeof req.query.tag is 'string' and req.query.tag isnt ''
        if req.query.tag.charAt(0) is '!' and req.query.tag.length > 1
          query['tags.0'] = $ne: req.query.tag.substr(1)
        else
          query['tags.0'] = req.query.tag

### ?grupper=`String`

      if typeof req.query.gruppe is 'string' and req.query.gruppe isnt ''
        query['grupper'] = req.query.gruppe

### ?after=`Mixed`

      if typeof req.query.after is 'string' and req.query.after isnt ''
        time = req.query.after

        if not isNaN time
          # Make unix timestamp into milliseconds
          time = time + '000' if (time + '').length is 10
          time = parseInt time

        time = new Date time

        if time.toString() isnt 'Invalid Date'
          query.endret = $gte: time.toISOString()

### ?bbox=`min_lng`,`min_lat`,`max_lng`,`max_lat`

      if typeof req.query.bbox is 'string' and req.query.bbox.split(',').length is 4
        bbox = req.query.bbox.split(',')
        bbox[i] = parseFloat(val) for val, i in bbox

        query.geojson =
          '$geoWithin':
            '$geometry':
              type: 'Polygon'
              coordinates: [[
                [bbox[0], bbox[1]]
                [bbox[2], bbox[1]]
                [bbox[2], bbox[3]]
                [bbox[0], bbox[3]]
                [bbox[0], bbox[1]]
              ]]

### ?privat.`String`=`String`

This allows the user to filter documents based on private document properties.
This will autumaticly limit returned documents to those owned by the current
user.

#### ToDo

 * Limit number of private fields?
 * Limit depth of private fields?

`NB` This section is looping through all of the url query parameters and hence
should take the queries from above sections into concideration so we don't need
to do double amount of work.

      for key, val of req.query when key.substr(0,7) is 'privat.'
        if /^[a-zæøåA-ZÆØÅ0-9_.]+$/.test key
          val = parseFloat(val) if not isNaN val # @TODO(starefossen) is this acceptable?
          query.tilbyder = req.usr
          query[key] = val

Limit queries to own documents or public documents i.e. where `doc.status` is
`Offentlig` if not `query.tilbyder` is set.

      query['$or'] = [{status: 'Offentlig'}, {tilbyder: req.usr}] if not query.tilbyder

Only project a few fields to since lists are mostly used intermediate before
fetching the entire document.

      fields = tilbyder: true, endret: true, status: true, navn: true, tags: true

Set up MongoDB options.

      options =
        limit: Math.min((parseInt(req.query.limit, 10) or 20), 50)
        skip: parseInt(req.query.skip, 10) or 0
        sort: 'endret'

Retrive matching documents from MongoDB.

      cursor = req.db.col.find(query, fields, options)
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


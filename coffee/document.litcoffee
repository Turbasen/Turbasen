    "use strict"

    ObjectID    = require('mongodb').ObjectID
    stringify   = require('JSONStream').stringify
    createHash  = require('crypto').createHash

    mongo       = require './db/mongo'
    cache       = require './cache'

## PARAM documentId

    exports.param = (req, res, next, id) ->
      return res.json 400, error: 'Ugyldig ObjectID' if not /^[a-f0-9]{24}$/.test id
      return next() if req.method is 'OPTIONS'

      cache.getForType req.type, id, (err, doc, cacheHit) ->
        return next err if err
        res.set 'X-Cache-Hit', cacheHit

        if doc.status is 'Slettet' or
        (doc.tilbyder isnt req.usr and doc.status isnt 'Offentlig')
          res.status(404)
          return res.json message: 'Objekt ikke funnet' if req.method isnt 'HEAD'
          return res.end()

        if doc.tilbyder isnt req.usr and req.method not in ['GET', 'HEAD']
          return res.json 403, message: 'Utilstrekkelige rettigheter'

        # doc.checksum - Not all data in the database has a computed checksum -
        # yet. This is becuase checksum computation was moved to data input layer
        # instead of chache retrival layer. Data which has not been updated since
        # 2013-01-14 will hence not have a computed checksum.

        return res.status(304).end() if req.get('If-None-Match') is doc.checksum and doc.checksum
        if not req.get('If-None-Match') and req.get('If-Modified-Since')

          since = req.get 'If-Modified-Since'
          if not isNaN since
            since += '000' if since.length is 10
            since = parseInt since

          d1 = new Date(doc.endret).setMilliseconds(0) # HTTP-date's don't have milliseconds
          d2 = new Date(since)

          return res.status(304).end() if d2.toString() isnt 'Invalid Date' and d1 <= d2

        req.doc = doc
        req.doc._id = new ObjectID(id)

        next()

## OPTIONS /{collection}/{documentId}

    exports.options = (req, res, next) ->
      res.setHeader 'Access-Control-Allow-Methods', 'HEAD, GET, PUT, PATCH, DELETE'
      res.send()

## GET /{collection}/{documentId}

    exports.get = (req, res, next) ->
      res.set 'ETag', req.doc.checksum if req.doc.checksum # @TODO(starefossen) checksum bug
      res.set 'Last-Modified', new Date(req.doc.endret).toUTCString()
      res.status(200)

      return res.end() if req.method is 'HEAD'
      res.set 'Content-Type', 'application/json; charset=utf-8'

      fields = if req.doc.tilbyder is req.usr then {} else {privat: false}
      req.db.col.find({_id: req.doc._id}, fields, {limit: 1})
        .stream()
        .pipe(stringify('','',''))
        .pipe(res)

## PUT /{collection}/{documentId}

    exports.put = (req, res, next) ->
      return res.json 400, message: 'Body is missing' if Object.keys(req.body).length is 0
      return res.json 400, message: 'Body should be a JSON Hash' if req.body instanceof Array

      warnings = []
      errors   = []
      message  = ''

      req.body._id = req.doc._id
      req.body.tilbyder = req.usr
      req.body.endret = new Date().toISOString()
      req.body.checksum = createHash('md5').update(JSON.stringify(req.body)).digest('hex')

      # @TODO(starefossen) use old value?
      if not req.body.lisens
        req.body.lisens = 'CC BY-ND-NC 3.0 NO'
        warnings.push
          resource: req.type
          field: 'lisens'
          value: req.body.lisens
          code: 'missing_field'

      # @TODO(starefossen) use old value?
      if not req.body.status
        req.body.status = 'Kladd'
        warnings.push
          resource: req.type
          field: 'status'
          value: req.body.status
          code: 'missing_field'

      req.db.col.save req.body, {safe: true, w: 1}, (err) ->
        return next(err) if err
        cache.setForType req.type, req.body._id, req.body, (err, data) ->
          return next(err) if err
          return res.json 200,
            document:
              _id: req.body._id
            count: 1
            message: message if message
            warnings: warnings if warnings.length > 0
            errors: errors if errors.length > 0

## PATCH /{collection}/{documentId}

    exports.patch = (req, res, next) ->
      res.json 501, message: 'HTTP method not implmented'
      # 200, object

## DELETE /{collection}/{documentId}

Delete the given document from Nasjonal Turbase. All user editable document
properties are delete and `doc.status` is set to `Slettet`.

`NB` There is a bug with the caching that prevents some fields from being
removed from the cahce. This must be handled.

    exports.delete = (req, res, next) ->

      doc =
        _id       : req.doc._id
        tilbyder  : req.doc.tilbyder
        endret    : new Date().toISOString()
        checksum  : null
        status    : 'Slettet'

      doc.checksum = createHash('md5').update(JSON.stringify(req.body)).digest('hex')

      req.db.col.save doc, {safe: true, w: 1}, (err) ->
        return next(err) if err
        cache.setForType req.type, doc._id, doc, (err, data) ->
          return next(err) if err
          return res.status(204).end()

    sentry   = require './db/sentry'
    Document = require './model/Document'

    stringify= require('JSONStream').stringify

## param()

    exports.param = (req, res, next, id) ->
      return res.status(400).json message: 'Invalid ObjectId' if not /^[a-f0-9]{24}$/.test id
      return next() if req.method is 'OPTIONS'

      req.doc = new Document(req.type, id).once('error', next).once 'ready', ->
        req.isOwner = @exists() and req.user.tilbyder is @get 'tilbyder'

        if not @exists() or (@get('status') isnt 'Offentlig' and not req.isOwner)
          return res.status(404).json message: 'Not Found' if req.method isnt 'HEAD'
          return res.status(404).end()

        next()


## all()

    exports.all = (req, res, next) ->
      res.set 'X-Cache-Hit', req.doc.wasCacheHit()
      res.set 'ETag', "\"#{req.doc.get 'checksum'}\""
      res.set 'Last-Modified', new Date(req.doc.get 'endret').toUTCString()

      if req.method not in ['GET', 'HEAD'] and not req.isOwner
        return res.status(403).json message: 'Request Denied'

      if req.get 'If-Match'
        return res.status(412).end() if req.doc.isNoneMatch req.get 'If-Match'

      else if req.get 'If-None-Match'
        return res.status(304).end() if req.doc.isMatch req.get 'If-None-Match'

      else
        if req.doc.isNotModifiedSince req.get 'If-Modified-Since'
          return res.status(304).end()

        if req.doc.isModifiedSince req.get 'If-Unmodified-Since'
          return res.status(412).end()

      next()


## options()

    exports.options = (req, res, next) ->
      res.set 'Access-Control-Allow-Methods', [
        'HEAD', 'GET', 'PUT', 'PATCH', 'DELETE'
      ].join ', '
      res.set 'Access-Control-Allow-Headers', [
        'Content-Type'
        'If-Match'
        'If-Modified-Since'
        'If-None-Match'
        'If-Unmodified-Since'
      ].join ', '
      res.sendStatus 204


## head()
## get()

    exports.head = exports.get = (req, res, next) ->
      return res.sendStatus 200 if req.method is 'HEAD'

      res.set 'Content-Type', 'application/json; charset=utf-8'
      req.doc.getFull if req.isOwner then {} else privat: false
        .stream()
        .pipe stringify '', '', ''
        .pipe res


## patch()
## put()

    exports.patch = exports.put = (req, res, next) ->
      return res.status(400).json message: 'Body is missing' if Object.keys(req.body).length is 0
      return res.status(400).json message: 'Body should be a JSON Hash' if req.body instanceof Array

      req.body.tilbyder = req.user.tilbyder

      method = (if req.method is 'PUT' then 'replace' else 'update')
      req.doc[method] req.body, (err, warn, data) ->
        if err
          return next(err) if err.name isnt 'ValidationError'

          sentry.captureDocumentError req, err

          return res.status(422).json
            document: req.body
            message: 'Validation Failed'
            errors: err.details #TODO(starefossen) document this

        res.set 'ETag', "\"#{data.checksum}\""
        res.set 'Last-Modified', new Date(data.endret).toUTCString()

        return res.status(200).json
          document: data
          message: 'Validation Warnings' if warn.length > 0
          warnings: warn if warn.length > 0


## delete()

    exports.delete = (req, res, next) ->
      req.doc.delete (err) ->
        return next err if err
        return res.sendStatus 204


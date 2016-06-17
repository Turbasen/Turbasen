    schema   = require './helper/schema'
    sentry   = require './db/sentry'
    Document = require './model/Document'

    JSONStream = require 'JSONStream'

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


## OPTIONS

```http
OPTIONS /{type}/{id}
```

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


## HEAD and GET

```http
HEAD /{type}/{id}
GET /{type}/{id}
```

    exports.head = exports.get = (req, res, next) ->
      return res.sendStatus 200 if req.method is 'HEAD'

      opts =
        query: $or: [{status: 'Offentlig'}, {tilbyder: req.user.tilbyder}]
        fields: {}

### Fields Projection

```
&fields=field1[,field2[,..]]
```

Private (`privat.`) fields are hidden unless the current API user is the owner
of the document. This is to prevent unauthorized information disclosure.

      opts.fields.privat = false if not req.isOwner

If you only want some of the document properties returned you can use the
`fields` query parameter to control the projection of document properties.
Multiple fields must be comma separated without any additional spacing.

This projection also applies to expanded sub-documents when using the `&expand=`
query parameter below.

      if req.query?.fields
        opts.fields[field] = true for field in req.query.fields.split ','
        opts.fields.privat = false if not req.isOwner

The list of default fields below will always be returned for compliance reasons.

        opts.fields = Object.assign opts.fields,
          endret: true
          lisens: true
          status: true
          navn  : true
          tilbyder  : true
          navngiving: true

### Sub-document Expansion

```
&expand=field1[,field2[..]]
```

Sub-document expansion is an easy and convenient way to get connected documents
such as `grupper`, `bilder`, and `områder` as their full objects instead of a
list of `ObjectIDs`. It works by setting the `expand` query parameter to the
fields to expand.

**Rate limit**

Sub-document expansion will decrease your remaining API rate limit with `1` per
collection expanded in addition to the request itself. Thus, if you request a
document (1) with two collection expanded (2) your remaining API rate limit will
be decremented with 3. This is to encurrage resonable expansion of relevant
collections only.

**Order and limit**

Sub-document expansion will return at most 10 first sub-documents for each
collection expanded and out of order. Only sub-documents avaiable to the current
API user will be return as sub-documents my not be published or may have been
deleted.

      if req.query?.expand
        opts.expand = req.query.expand.split ','

### Sub-document Limit

```
&limit={n}
```

If you wisth to return less sub-documents in order to increase response time and
body size you may do so by using the `limit` query parameter. This will affect
all sub-documents expanded by the `expand` query parameter.

      if req.query?.limit and parseInt req.query.limit, 10
        opts.limit = parseInt req.query.limit, 10

---

      req.doc.getExpanded opts, (err, doc) ->
        return next err if err
        res.json doc


## PUT and PATCH

```http
PUT /{type}/{id}
PATCH /{type}/{id}
```

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


## DELETE

```http
DELETE /{type}/{id}
```

    exports.delete = (req, res, next) ->
      req.doc.delete (err) ->
        return next err if err
        return res.sendStatus 204


"use strict"

ObjectID = require('mongodb').ObjectID

exports.param = (req, res, next, id) ->
  return res.json 400, error: 'Ugyldig ObjectID' if not /^[a-f0-9]{24}$/.test id
  return next() if req.method is 'OPTIONS'

  req.cache.get req.col, id, (err, doc, cacheHit) ->
    return next err if err
    res.set 'X-Cache-Hit', cacheHit

    if doc.status is 'Slettet' or
    (doc.tilbyder isnt req.usr and
    (req.method not in ['HEAD', 'GET'] or doc.status isnt 'Offentlig'))
      res.status(404)
      return res.json error: 'Document Not Found' if req.method isnt 'HEAD'
      return res.end()

    return res.status(304).end() if req.get('If-None-Match') is doc.checksum
    return res.status(304).end() if req.get('If-Modified-Since') >= doc.endret

    req.doc = doc
    req.doc._id = new ObjectID(id)

    next()

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'HEAD, GET, PUT, PATCH, DELETE'
  res.send()

exports.get = (req, res, next) ->
  res.set 'ETag', req.doc.checksum
  res.set 'Last-Modified', new Date(req.doc.endret).toUTCString()
  res.status(200)

  fields = if req.doc.tilbyder is req.usr then {} else {privat: false}

  return res.end() if req.method is 'HEAD'
  req.cache.getCol(req.col).findOne {_id: req.doc._id}, fields, (err, doc) ->
    return res.json doc if not err
    return next(err)

exports.put = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 200, object

exports.patch = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 200, object

exports.delete = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 204


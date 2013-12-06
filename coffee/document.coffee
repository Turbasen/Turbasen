"use strict"

ObjectID = require('mongodb').ObjectID

exports.param = (req, res, next, id) ->
  return res.json 400, error: 'Ugyldig ObjectID' if not /^[a-f0-9]{24}$/.test id
  return next() if req.method is 'OPTIONS'

  req.cache.get req.type, id, (err, doc, cacheHit) ->
    return next err if err
    res.set 'X-Cache-Hit', cacheHit

    return res.json 404, error: 'Document Not Found' if doc.status is 'Slettet'
    # @TODO check rights for non public documents here
    return res.status(304).end() if req.get('If-None-Match') is doc.checksum
    return res.status(304).end() if req.get('If-Modified-Since') >= doc.endret

    # @TODO what if PUT/PATCH
    res.set 'ETag', doc.checksum
    res.set 'Last-Modified', new Date(doc.endret).toUTCString()
    req.id = new ObjectID id

    next()

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'GET, PUT, PATCH, DELETE'
  res.send()

exports.get = (req, res, next) ->
  req.col.findOne {_id: req.id}, (err, doc) ->
    return res.json 200, doc if not err
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


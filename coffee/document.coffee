"use strict"

ObjectID = require('mongodb').ObjectID
crypto = require('crypto')

exports.param = (req, res, next, id) ->
  return res.json 400, error: 'Invalid ObjectID' if not /^[a-f0-9]{24}$/.test id
  req.id = new ObjectID id
  return next() if req.method is 'OPTIONS'

  result = (err, doc) ->
    if not doc or doc.status is 'Slettet'
      return res.json 404, error: 'Document Not Found'
    req.etag = crypto.createHash('md5').update(req.id + doc.endret).digest("hex")
    return res.status(304).end() if req.get('if-none-match') is req.etag
    res.set 'ETag', req.etag
    res.set 'Last-Modified', new Date(doc.endret).toUTCString()
    cb = err = doc = null
    next()

  key = "#{req.type}:#{req.id}"
  req.cache.hgetall key, (err, data) ->
    if data and typeof req.query.nocache is 'undefined'
      res.set 'X-Cache-Hit', 'true'
      return result(null, data)

    req.col.find({_id: req.id}, {endret: true, status: true}, {limit: 1}).toArray (err, docs) ->
      endret = docs[0]?.endret or new Date().toISOString()
      status = docs[0]?.status or 'Slettet'

      req.cache.hmset key, "endret", endret, "status", status, (err, data) ->
        result null,
          endret: endret
          status: status

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'GET, PUT, PATCH, DELETE'
  res.send()

exports.get = (req, res, next) ->
  cb = (err, doc) ->
    if doc
      res.json 200, doc
    else if err
      next err
    else
      res.json 404, error: 'Document Not Found'

    cb = err = doc = null
    return

  req.col.findOne _id: req.id, cb

exports.put = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 200, object

exports.patch = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 200, object

exports.delete = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 204


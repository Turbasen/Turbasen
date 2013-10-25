"use strict"

ObjectID = require('mongodb').ObjectID
crypto = require('crypto')

exports.param = (req, res, next, id) ->
  return res.json 400, error: 'Invalid ObjectID' if not /^[a-f0-9]{24}$/.test id
  req.id = new ObjectID id
  return next() if req.method is 'OPTIONS'
  req.col.find({_id: req.id}, {endret: true}, {limit: 1}).toArray (err, docs) ->
    return res.json 404, error: 'Document Not Found' if docs.length is 0
    req.etag = crypto.createHash('md5').update(docs[0]._id + docs[0].endret).digest("hex")
    return res.status(304).end() if req.get('if-none-match') is req.etag
    res.set 'ETag', req.etag
    res.set 'Last-Modified', new Date(docs[0].endret).getTime()
    err = docs = null
    next()

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'GET, PUT, PATCH, DELETE'
  res.send()

exports.get = (req, res, next) ->
  req.col.findOne _id: req.id, (err, doc) ->
    return next err if err
    if doc
      res.json 200, doc
      err = docs = null
      return
    return res.json 404, error: 'Document Not Found'

exports.put = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 200, object

exports.patch = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 200, object

exports.delete = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'
  # 204


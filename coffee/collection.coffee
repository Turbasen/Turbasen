"use strict"

ObjectID = require('mongodb').ObjectID

collections = {}

exports.param = (req, res, next, collection) ->
  if collections[collection]
    req.col = collections[collection]
    return next()

  req.db.collection collection, (err, col) ->
    return next err if err
    collections[collection] = req.col = col
    return next()

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT'
  res.send()

exports.get = (req, res, next) ->
  query = {}
  query.endret = {$gte:req.query.after} if typeof req.query.after is 'string'

  fields = {}
  fields = navn: true, endret: true

  options =
    limit: Math.min((parseInt(req.query.limit) or 20), 50)
    skip: parseInt(req.query.skip) or 0
    sort: 'endret'

  req.col.find(query, fields, options).toArray (err, docs) ->
    return next err if err
    res.json documents: docs, count: docs.length

exports.post = (req, res, next) ->
  return res.json 400, message: 'Payload data is missing' if Object.keys(req.body).length is 0
  req.body = [req.body] if (req.body instanceof Array) is false

  ret = []
  cnt = 0
  for item, i in req.body
    item._id = ObjectID(item._id) if item._id # @TODO restrict this
    # @TODO item.opprettet
    # @TODO item.endret
    # @TODO item.tilbyder
    do (item, i) ->
      req.col.save item, {safe: true, w: 1}, (err, doc) ->
        return next(err) if err
        ret[i] = doc._id or item._id # doc is 1 if updated
        return res.json 201, documents: ret, count: ret.length if ++cnt is req.body.length

exports.patch = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'

exports.put = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'


"use strict"

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
  fields = {navn: true}
  options =
    limit: req.query.limit or 20
    skip: req.query.skip or 0
    sort: 'endret'

  req.col.find(query, fields, options).toArray (err, docs) ->
    return next err if err
    res.json documents: docs, count: docs.length

exports.post = (req, res, next) ->
  return res.send 400, 'Missing Request Payload' if Object.keys(req.body).length is 0
  req.col.insert req.body, (err, doc) ->
    return next(err) if err
    return res.json 201, documents: doc, count: doc.length

exports.patch = (req, res, next) ->
  res.send 501, 'Not Implmented'

exports.put = (req, res, next) ->
  res.send 501, 'Not Implmented'


"use strict"

ObjectID = require('mongodb').ObjectID

exports.param = (req, res, next, id) ->
  return res.send 400, 'invalid oid' if not /[a-f0-9]{24}/.test id
  req.id = new ObjectID id
  next()

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'GET, PUT, PATCH, DELETE'
  res.send()

exports.get = (req, res, next) ->
  req.col.findOne _id: req.id, (err, doc) ->
    return next err if err
    return res.json 200, documents: [doc], count: 1 if doc
    return res.json 404, error: 'Document Not Found'

exports.put = (req, res, next) ->
  res.send 501, 'Not Implemented'
  # 200, object

exports.patch = (req, res, next) ->
  res.send 501, 'Not Implemented'
  # 200, object

exports.delete = (req, res, next) ->
  res.send 501, 'Not Implemented'
  # 204


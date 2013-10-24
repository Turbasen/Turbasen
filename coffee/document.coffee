"use strict"

ObjectID = require('mongodb').ObjectID

exports.param = (req, res, next, id) ->
  return res.json 400, error: 'Invalid ObjectID' if not /^[a-f0-9]{24}$/.test id
  req.id = new ObjectID id
  next()

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'GET, PUT, PATCH, DELETE'
  res.send()

exports.get = (req, res, next) ->
  req.col.findOne _id: req.id, (err, doc) ->
    return next err if err
    if doc
      res.set 'Last-Modified', new Date(doc.endret).getTime()
      return res.json 200, doc
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


"use strict"

ObjectID = require('mongodb').ObjectID

collections = {}

exports.param = (req, res, next, collection) ->
  if collection not in ['turer', 'steder', 'grupper', 'områder', 'bilder', 'aktiviteter']
    return res.json 404,
      message: 'Objekttype ikke funnet'

  req.type = collection

  if collections[collection]
    req.col = collections[collection]
    return next()

  cb = (err, col) ->
    return next err if err
    collections[collection] = req.col = col
    next()

  req.db.collection collection, cb

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT'
  res.send()

exports.get = (req, res, next) ->
  query = {}
  if typeof req.query.tag is 'string' and req.query.tag isnt ''
    if req.query.tag.charAt(0) is '!' and req.query.tag.length > 1
      query['tags.0'] = $ne: req.query.tag.substr(1)
    else
      query['tags.0'] = req.query.tag

  if typeof req.query.after is 'string' and req.query.after isnt ''
    if not isNaN(req.query.after)
      req.query.after = new Date(parseInt(req.query.after, 10)).toISOString()
    query.endret = {$gte:req.query.after}

  fields = endret: true, status: true, navn: true

  options =
    limit: Math.min((parseInt(req.query.limit, 10) or 20), 50)
    skip: parseInt(req.query.skip, 10) or 0
    sort: 'endret'

  total = 0
  cursor = req.col.find(query, fields, options)
  query = fields = options = null

  countCb = (err, t) ->
    return next err if err
    return res.json documents: [], count: 0, total: 0 if t is 0
    total = t
    return cursor.toArray cursorCb

  cursorCb = (err, docs) ->
    return next err if err
    return res.json documents: docs, count: docs.length, total: total

  return cursor.count countCb

exports.post = (req, res, next) ->
  return res.json 400, message: 'Body is missing' if Object.keys(req.body).length is 0
  return res.json 422, message: 'Body should be a JSON Hash' if req.body instanceof Array

  warnings = []
  errors   = []
  message  = ''

  req.body._id = new ObjectID(req.body._id) # @TODO restrict this
  req.body.tilbyder = req.usr
  req.body.endret = new Date().toISOString()

  if not req.body.lisens
    req.body.lisens = 'CC BY-ND-NC 3.0 NO'
    warnings.push
      resource: req.type
      field: 'lisens'
      value: req.body.lisens
      code: 'missing_field'

  if not req.body.status
    req.body.status = 'Kladd'
    warnings.push
      resource: req.type
      field: 'status'
      value: req.body.status
      code: 'missing_field'

  req.col.save req.body, {safe: true, w: 1}, (err) ->
    return next(err) if err
    req.cache.hmset [
      "#{req.type}:#{req.body._id}"
      'tilbyder', req.body.tilbyder
      'endret', req.body.endret
      'status', req.body.status
    ], () -> return
    return res.json 201,
      document:
        _id: req.body._id
      count: 1
      message: message if message
      warnings: warnings if warnings.length > 0
      errors: errors if errors.length > 0

exports.patch = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'

exports.put = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'


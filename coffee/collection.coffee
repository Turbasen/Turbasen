"use strict"

ObjectID = require('mongodb').ObjectID

collections = {}

exports.param = (req, res, next, collection) ->
  # @TODO url-decode collection
  # @TODO restricted collections
  if collections[collection]
    req.col = collections[collection]
    return next()

  cb = (err, col) ->
    if col
      collections[collection] = req.col = col
      next()
    else
      next err

    cb = err = col = null
    return

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

  fields = {}
  fields = navn: true, endret: true

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
  return res.json 400, message: 'Payload data is missing' if Object.keys(req.body).length is 0
  req.body = [req.body] if (req.body instanceof Array) is false

  # @TODO this method should only do insert

  # Loop through items
  #
  # -throw error if _id exists
  # -add item.opprettet
  # -add item.endret
  # -add item.tilbyder
  # -check item.lisens
  # -check item.status

  ret = []
  cnt = req.body.length
  for item in req.body
    item._id = new ObjectID(item._id) if item._id # @TODO restrict this
    item._id = new ObjectID() if not item._id
    ret.push(item._id)

    req.col.save item, {safe: true, w: 1}, (err, doc) ->
      return next(err) if err
      return res.json 201, documents: ret, count: ret.length if --cnt is 0

exports.patch = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'

exports.put = (req, res, next) ->
  res.json 501, message: 'HTTP method not implmented'


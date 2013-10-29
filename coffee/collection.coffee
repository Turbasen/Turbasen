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

  cursor = req.col.find(query, fields, options)
  cursor.count (err, total) ->
    if err
      next err
      cursor = err = total = null
      return

    if total is 0
      res.json documents: [], count: 0, total: 0
      cursor = err = total = null
      return
    
    err = null

    cursor.toArray (err, docs) ->
      if err
        next err
      else
        res.json documents: docs, count: docs.length, total: total
      
      cursor = err = docs = total = null
      return

  query = fields = options = null
  return

exports.post = (req, res, next) ->
  return res.json 400, message: 'Payload data is missing' if Object.keys(req.body).length is 0
  req.body = [req.body] if (req.body instanceof Array) is false

  ret = []
  cnt = 0
  for item, i in req.body
    item._id = new ObjectID(item._id) if item._id # @TODO restrict this
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


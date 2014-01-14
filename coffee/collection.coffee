"use strict"

ObjectID = require('mongodb').ObjectID
stringify = require('JSONStream').stringify
createHash = require('crypto').createHash

exports.param = (req, res, next, col) ->
  if col not in ['turer', 'steder', 'grupper', 'områder', 'bilder', 'aktiviteter']
    return res.json 404, message: 'Objekttype ikke funnet'

  req.col = col
  next()

exports.options = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Methods', 'HEAD, GET, POST, PATCH, PUT'
  res.send()

exports.get = (req, res, next) ->
  query = {}
  if typeof req.query.tag is 'string' and req.query.tag isnt ''
    if req.query.tag.charAt(0) is '!' and req.query.tag.length > 1
      query['tags.0'] = $ne: req.query.tag.substr(1)
    else
      query['tags.0'] = req.query.tag

  if typeof req.query.gruppe is 'string' and req.query.gruppe isnt ''
    query['grupper'] = req.query.gruppe

  if typeof req.query.after is 'string' and req.query.after isnt ''
    if not isNaN(req.query.after)
      req.query.after = new Date(parseInt(req.query.after, 10)).toISOString()
    query.endret = {$gte:req.query.after}

  fields = endret: true, status: true, navn: true

  options =
    limit: Math.min((parseInt(req.query.limit, 10) or 20), 50)
    skip: parseInt(req.query.skip, 10) or 0
    sort: 'endret'

  cursor = req.cache.getCol(req.col).find(query, fields, options)
  cursor.count (err, total) ->
    return next err if err
    res.set 'Count-Return', Math.min(options.limit, total)
    res.set 'Count-Total', total
    return res.end() if req.method is 'HEAD'
    return res.json documents: [], count: 0, total: 0 if total is 0
    res.set 'Content-Type', 'application/json; charset=utf-8'

    op = '{"documents":['
    cl = '],"count":' + Math.min(options.limit, total) + ',"total":' + total + '}'

    cursor.stream().pipe(stringify(op, ',', cl)).pipe(res)

exports.post = (req, res, next) ->
  #
  # @TODO move update to :/collection/:document
  # @TODO add access control
  #

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
      resource: req.col
      field: 'lisens'
      value: req.body.lisens
      code: 'missing_field'

  if not req.body.status
    req.body.status = 'Kladd'
    warnings.push
      resource: req.col
      field: 'status'
      value: req.body.status
      code: 'missing_field'

  req.body.checksum = createHash('md5').update(JSON.stringify(req.body)).digest("hex")

  req.cache.getCol(req.col).save req.body, {safe: true, w: 1}, (err) ->
    return next(err) if err
    req.cache.set req.col, req.body._id, req.body, (err, data) ->
      return next(err) if err
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


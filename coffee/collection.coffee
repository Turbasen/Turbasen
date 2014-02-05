"use strict"

ObjectID    = require('mongodb').ObjectID
stringify   = require('JSONStream').stringify
createHash  = require('crypto').createHash

mongo       = require './db/mongo'
cache       = require './cache'

exports.param = (req, res, next, col) ->
  if col not in ['turer', 'steder', 'grupper', 'områder', 'bilder', 'arrangementer']
    return res.json 404, message: 'Objekttype ikke funnet'

  req.type = col
  req.db   = col: mongo[col]

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

  if typeof req.query.bbox is 'string' and req.query.bbox.split(',').length is 4
    bbox = req.query.bbox.split(',')
    bbox[i] = parseFloat(val) for val, i in bbox

    query.geojson =
      '$geoWithin':
        '$geometry':
          type: 'Polygon'
          coordinates: [[
            [bbox[0], bbox[1]]
            [bbox[2], bbox[1]]
            [bbox[2], bbox[3]]
            [bbox[0], bbox[3]]
            [bbox[0], bbox[1]]
          ]]

  # @TODO(starefossen) limit number of private fields
  # @TODO(starefossen) limit depth of private field
  for key, val of req.query when key.substr(0,7) is 'privat.'
    if /^[a-zæøåA-ZÆØÅ0-9_.]+$/.test key
      val = parseFloat(val) if not isNaN val # @TODO(starefossen) is this acceptable?
      query.tilbyder = req.usr
      query[key] = val

  # Limit queries to own documents or public documents ie. status = 'Offentlig'
  query['$or'] = [{status: 'Offentlig'}, {tilbyder: req.usr}] if not query.tilbyder

  fields = tilbyder: true, endret: true, status: true, navn: true

  options =
    limit: Math.min((parseInt(req.query.limit, 10) or 20), 50)
    skip: parseInt(req.query.skip, 10) or 0
    sort: 'endret'

  cursor = req.db.col.find(query, fields, options)
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

  req.body.checksum = createHash('md5').update(JSON.stringify(req.body)).digest("hex")

  req.db.col.save req.body, {safe: true, w: 1}, (err) ->
    return next(err) if err
    cache.setForType req.type, req.body._id, req.body, (err, data) ->
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


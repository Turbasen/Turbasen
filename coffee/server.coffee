"use strict"

express = require 'express'
MongoClient = require('mongodb').MongoClient

collection = require './collection'
document = require './document'

app = module.exports = express()

error = (status, msg) ->
  err = new Error(msg)
  err.status = status
  err

# API key
app.use '/', (req, res, next) ->
  key = req.query['api_key']

  return res.send 400, 'api key required' if not key
  return res.send 401, 'invalid api key' if not apiKeys[key]

  req.key = key
  req.db = app.get 'db'
  
  res.setHeader 'Access-Control-Allow-Origin', '*'

  next()

app.use(express.favicon())
app.use(express.logger(':date - :method :url - :res[content-type]')) if not process.env.SILENT
app.set('json spaces', 0) if app.get('env') is 'production'
app.use(express.compress())
app.use(express.methodOverride())
app.use(express.bodyParser())
app.disable('x-powered-by')
app.enable('verbose errors')
app.set 'port', process.env.PORT or 8080
app.use(app.router)

# Error Handler
app.use (err, req, res, next) ->
  status = err.status or 500
  message = err.message or 'Unknown Error'
  res.json status, error: message

  console.error err.message
  console.error err.stack

app.use (req, res) -> res.json 404, error: "Lame, can't find that"

apiKeys =
  dnt: 'DNT'
  nrk: 'NRK'

app.get '/', (req, res) ->
  res.json 'Here be dragons'

app.param 'objectid', document.param
app.all '/:collection/:objectid', (req, res, next) ->
  switch req.method
    when 'OPTIONS' then document.options req, res, next
    when 'GET' then document.get req, res, next
    when 'PUT' then document.put req, res, next
    when 'PATCH' then document.patch req, res, next
    when 'DELETE' then document.delete req, res, next
    else res.send 405, ''

app.param 'collection', collection.param
app.all '/:collection', (req, res, next) ->
  switch req.method
    when 'OPTIONS' then collection.options req, res, next
    when 'GET' then collection.get req, res, next
    when 'POST' then collection.post req, res, next
    when 'PUT'  then collection.put req, res, next
    when 'PATCH' then collection.patch req, res, next
    else res.send 405, ''

MongoClient.connect process.env.MONGO_URI, (err, db) ->
  return err if err
  app.set 'db', db
  if not module.parent
    app.listen app.get 'port'
    console.log "Server is listening on port #{app.get('port')}"
  else
    app.emit 'ready'


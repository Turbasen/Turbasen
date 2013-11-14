"use strict"

express = require 'express'
raven   = require 'raven'
MongoClient = require('mongodb').MongoClient

collection = require './collection'
document = require './document'

app = module.exports = express()

# API key
app.use '/', (req, res, next) ->
  key = req.query.api_key

  return res.json 403, message: 'API key missing' if not key
  return res.json 401, message: 'API key invalid' if not apiKeys[key]

  req.key = key
  req.usr = apiKeys[key]
  req.db = app.get 'db'

  res.setHeader 'Access-Control-Allow-Origin', '*'

  next()

app.use(express.favicon())
app.use(express.logger(':date :remote-addr - :method :url :status :res[content-length] - :response-time ms')) if not process.env.SILENT
app.set('json spaces', 0) if app.get('env') isnt 'testing'
app.use(express.compress())
app.use(express.methodOverride())
app.use(express.json())
app.disable('x-powered-by')
app.enable('verbose errors')
app.set 'port', process.env.PORT_WWW or 8080
app.use(app.router)
app.use(raven.middleware.express(process.env.SENTRY_DNS)) if process.env.SENTRY_DNS

# Error Handler
app.use (err, req, res, next) ->
  status = err.status or 500
  message = err.message or 'Unknown Error'
  res.json status, message: message

  console.error err.message
  console.error err.stack

app.use (req, res) -> res.json 404, message: "Resource not found"

apiKeys =
  dnt: 'DNT'
  nrk: 'NRK'
  '30ad3a3a1d2c7c63102e09e6fe4bb253': 'TurApp'
  '0fe3cf9a548f7e158a4a0f5f22a9e8bd': 'UTno'

app.get '/', (req, res) ->
  res.json message: 'Here be dragons'

app.get '/objekttyper', (req, res, next) ->
  res.json 200, ['turer', 'steder', 'områder', 'grupper', 'aktiviteter', 'bilder']

app.get '/system', (req, res, next) ->
  os = require 'os'
  res.json 200,
    app:
      uptime: process.uptime()
      memory: process.memoryUsage()
    os:
      uptime: os.uptime()
      loadavg: os.loadavg()
      totalmem: os.totalmem()
      freemem: os.freemem()

app.get '/system/gc', (req, res, next) ->
  global.gc() if typeof global.gc is 'function'
  res.end()

app.param 'objectid', document.param
app.all '/:collection/:objectid', (req, res, next) ->
  switch req.method
    when 'OPTIONS' then document.options req, res, next
    when 'GET' then document.get req, res, next
    when 'PUT' then document.put req, res, next
    when 'PATCH' then document.patch req, res, next
    when 'DELETE' then document.delete req, res, next
    else res.json 405, message: 'HTTP method not supported'

app.param 'collection', collection.param
app.all '/:collection', (req, res, next) ->
  switch req.method
    when 'OPTIONS' then collection.options req, res, next
    when 'GET' then collection.get req, res, next
    when 'POST' then collection.post req, res, next
    when 'PUT'  then collection.put req, res, next
    when 'PATCH' then collection.patch req, res, next
    else res.json 405, message: 'HTTP method not supported'

MongoClient.connect process.env.MONGO_URI, (err, db) ->
  return err if err
  app.set 'db', db

  if not module.parent
    app.listen app.get 'port'
    console.log "Server is listening on port #{app.get('port')}"
  else
    app.emit 'ready'


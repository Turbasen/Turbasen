"use strict"

express     = require 'express'
raven       = require 'raven'

MongoClient = require('mongodb').MongoClient
Cache       = require('./Cache.class')

system      = require './system'
collection  = require './collection'
document    = require './document'

app = module.exports = express()

# API key
app.use '/', (req, res, next) ->
  key = req.query.api_key

  return res.json 403, message: 'API key missing' if not key
  return res.json 401, message: 'API key invalid' if not apiKeys[key]

  req.key = key
  req.usr = apiKeys[key]
  req.cache = app.get 'cache'

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
  res.status(err.status or 500)

  console.error err.message
  console.error err.stack

  return res.end() if req.method is 'HEAD'
  return res.json message: err.message or 'Ukjent feil'

app.use (req, res) -> res.json 404, message: "Resurs ikke funnet"

apiKeys =
  dnt: 'DNT'
  nrk: 'DNT'

  '30ad3a3a1d2c7c63102e09e6fe4bb253': 'TurApp'
  'b523ceb5e16fb92b2a999676a87698d1': 'Pingdom'

  '4c802ac2315ab24db9c992cc6eea0278': 'DNT' # ETA
  'de2986ac75c5af9d7f92a26f37dc1b77': 'DNT' # sherpa2.api
  '5dd5a39057cb479c3c4bce7f9eae5e6c': 'DNT' # dev.ut.no
  '146bbe01b477e9e07e85e0ddd3f5095a': 'DNT' # beta.ut.no
  'e6fa27292ffbcc689c49179c47bc708e': 'DNT' # prod.ut.no

app.get '/', (req, res) ->
  res.json message: 'Here be dragons'

app.get '/objekttyper', (req, res, next) ->
  res.json 200, ['turer', 'steder', 'områder', 'grupper', 'aktiviteter', 'bilder']

app.get '/system', system.info
app.get '/system/gc', system.gc
app.get '/CloudHealthCheck', system.check

app.param 'objectid', document.param
app.all '/:collection/:objectid', (req, res, next) ->
  switch req.method
    when 'OPTIONS' then document.options req, res, next
    when 'HEAD', 'GET' then document.get req, res, next
    when 'PUT' then document.put req, res, next
    when 'PATCH' then document.patch req, res, next
    when 'DELETE' then document.delete req, res, next
    else res.json 405, message: 'HTTP method not supported'

app.param 'collection', collection.param
app.all '/:collection', (req, res, next) ->
  switch req.method
    when 'OPTIONS' then collection.options req, res, next
    when 'HEAD', 'GET' then collection.get req, res, next
    when 'POST' then collection.post req, res, next
    when 'PUT'  then collection.put req, res, next
    when 'PATCH' then collection.patch req, res, next
    else res.json 405, message: 'HTTP method not supported'

MongoClient.connect process.env.MONGO_URI, (err, db) ->
  return err if err

  redisPort = process.env.DOTCLOUD_CACHE_REDIS_PORT or 6379
  redisHost = process.env.DOTCLOUD_CACHE_REDIS_HOST or 'localhost'
  redisPass = process.env.DOTCLOUD_CACHE_REDIS_PASSWORD or null

  app.set 'cache', new Cache db, redisPort, redisHost, redisPass

  if not module.parent
    app.listen app.get 'port'
    console.log "Server is listening on port #{app.get('port')}"
  else
    app.emit 'ready'


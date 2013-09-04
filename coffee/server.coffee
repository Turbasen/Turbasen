# 
# Nasjonal Turbase API - CoffeeScript
#

express = require 'express'
app     = express()

api.    = require './api.api'

# Application Settings
app.set 'debug', process.env['DEBUG'] || false
app.set 'mode',  process.env['MODE']  || 'local'
app.set 'port',  process.env['PORT']  || 8080

app.set 'trust proxy', true
app.set 'json spaces', 0 if app.get('mode') is 'production'
app.set 'strict routing', false

app.use express.logger()
app.use express.errorHandler()
app.use express.compress()
app.use express.methodOverride()
app.use express.bodyParser()
app.use app.router()

# Attach database instance
app.use (req, res, next) ->
  req.db.con = app.get 'db'
  next()

# Error handling
app.use (err, req, res, next) ->
  console.error err.stack if app.get 'debug'

  code = err.code || 500
  mesg = err.mesg || 'InternalServerError'

  res.jsonp code, err: mesg

# REST API key verificiation
app.use api.apiKeyVerificiation

app.param 'id', api.paramId
app.param 'object', api.paramObject

app.get '/', (req , res, next) -> res.end()
app.get '/objekttyper', api.getObjectTypes

# Object type
app.all '/:object/', (req, res, next) ->
  switch req.query.method
    when 'post' then api.insert req, res, next
    when 'put' then api.updates req, res, next
    when 'del' then api.deletes req, res, next
    else api.list req, res, next

# Single object
app.all '/:object/:id/', (req, res, next) ->
  switch req.query.method
    when 'post' then next new Error('MethodNotSupported')
    when 'put' then api.update req, res, next
    when 'del' then api.delete req, res, next
    else api.get req, res, next

# Connect to database
switch process.env.MODE
  when 'development' then uri = process.env.MONGO_DEV_URI
  when 'stage'       then uri = process.env.MONGO_STAGE_URI
  when 'production'  then uri = process.env.MONGO_PROD_URI
                     else uri = process.env.MONGO_LOCAL_URI

ntb = database.connect uri, (err, db) ->
  return console.log 'db con failed' if err
  
  app.set 'db', ntb
  module.exports = app

  if not module.parent
    srv = app.listen app.get 'port'
    srv.on 'close', ->
      console.log 'closing server port...'
      srv = app = null
      return
    
    console.log "Nasjonal Turbase is running on port #{ app.get 'port' }"
    console.log "API mode is #{ app.get 'mode' }, debug mode is #{ app.get 'debug' }"
  else
    srv = null


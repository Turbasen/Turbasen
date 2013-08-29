# 
# Nasjonal Turbase API - CoffeeScript
#

express = require 'express'
app     = express()
turbase = require './turbase'

# Set debug initially to false
app.set 'debug', process.env['DEBUG'] || false
app.set 'mode',  process.env['MODE']  || 'local'
app.set 'port',  process.env['PORT']  || 8080

# Logging
# app.use express.logger()
# Query params
app.use express.bodyParser()
# Error handling
app.use express.errorHandler()

# Hvis data sendes med, så sanitize data og legg til eier (fra api-key etter hvert)

# Hent eier ut fra api-key.
app.use (req, res, next) ->
  eiere =
    "dnt":
      "navn": "DNT"
    "nrk":
      "navn": "NRK"

  if not req?.query?.api_key or not eiere[req.query.api_key]
    err = new Error('API Authentication Failed')
    err.mesg = 'AuthenticationFailed'
    err.code = 403
    return next err

  req.eier = eiere[req.query.api_key].navn

  data = req.params?.data or req.query?.data
  if data
    req.data = JSON.parse data if data
    req.data.eier = req.eier

  next()

# Routing
app.use app.router
# Configure for reverse proxy
app.enable 'trust proxy'

app.all '/',(req, res) ->
  intro = "
  API for Nasjonal Turbase. Versjon 0.
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/?api_key=dnt'>http://api.nasjonalturbase.no/v0/turer/?api_key=dnt</a>
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/50ceff817f706c9d57000008?api_key=dnt'>http://api.nasjonalturbase.no/v0/turer/508598979f938fd06740ee75?api_key=dnt</a>
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/?api_key=dnt&method=post&data={%22Navn%22:%22Testtur%22,%22Beskrivelse%22:%22Dette%20er%20en%20test%22}'>http://api.nasjonalturbase.no/v0/turer/?api_key=dnt&method=post&data={%22Navn%22:%22Testtur%22,%22Beskrivelse%22:%22Dette%20er%20en%20test%22}</a>
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/50ceff817f706c9d57000008?api_key=dnt&method=put&data={%22Beskrivelse%22:%22N%C3%A5%20funker%20det%20som%20snuuuus%22}'>http://api.nasjonalturbase.no/v0/turer/508ec09cd71b8f0000000001?api_key=dnt&method=put&data={%22Beskrivelse%22:%22N%C3%A5%20funker%20det%20som%20snuuuus%22}</a>
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/50ceff817f706c9d57000008?api_key=dnt&method=del'>http://api.nasjonalturbase.no/v0/turer/508ec09cd71b8f0000000001?api_key=dnt&method=del</a>
  "
  res.send intro

app.param 'id', (req, res, next, id) ->
  if /^[0-9a-f]{24}$/i.test id
    next()
  else
    err = new Error('ID is not a string of 24 hex chars')
    err.code = 400
    err.mesg = 'ObjectIDMustBe24HexChars'
    next err

app.get '/objekttyper', turbase.getTypes

app.all '/:object/', (req, res) ->
  switch req.query.method
    when 'post' then turbase.insert req, res
    when 'put' then turbase.updates req, res
    when 'del' then turbase.deletes req, res
    else turbase.list req, res

app.all '/:object/:id', (req, res) ->
  switch req.query.method
    when 'post' then res.send 'Error'
    when 'put' then turbase.update req, res
    when 'del' then turbase.delete req, res
    else turbase.get req, res

# Error handling
app.use (err, req, res, next) ->
  console.error err.stack if app.get 'debug'

  code = err.code || 500
  mesg = err.mesg || 'InternalServerError'

  res.jsonp code, err: mesg

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
  module.exports = app


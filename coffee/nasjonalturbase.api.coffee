# 
# Nasjonal Turbase API - CoffeeScript
#

express = require 'express'
app     = express()
turbase = require '../src/turbase'

# Logging
app.use express.logger()
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

  req.eier = eiere[req.query.api_key]?.navn or res.end 'api_key parameter mangler eller er feil'

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
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/'>http://api.nasjonalturbase.no/v0/turer/</a>
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/508598979f938fd06740ee75'>http://api.nasjonalturbase.no/v0/turer/508598979f938fd06740ee75</a>
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/?method=post&data={%22Navn%22:%22Testtur%22,%22Beskrivelse%22:%22Dette%20er%20en%20test%22}'>http://api.nasjonalturbase.no/v0/turer/?method=put&data={%22Navn%22:%22Testtur%22,%22Beskrivelse%22:%22Dette%20er%20en%20test%22}</a>
  <br /><a href='http://api.nasjonalturbase.no/v0/turer/508ec09cd71b8f0000000001?method=put&data={%22Beskrivelse%22:%22N%C3%A5%20funker%20det%20som%20snuuuus%22}'>http://api.nasjonalturbase.no/v0/turer/508ec09cd71b8f0000000001?method=put&data={%22Beskrivelse%22:%22N%C3%A5%20funker%20det%20som%20snuuuus%22}</a>
  "
  res.send intro

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
  console.error err.stack
  res.jsonp 500, {'err':err}

app.listen 3000
console.log 'Nasjonal turbase running on port 3000'

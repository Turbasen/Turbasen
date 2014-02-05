    "use strict"

    express     = require 'express'
    raven       = require 'raven'

    system      = require './system'
    collection  = require './collection'
    document    = require './document'

## Init

    app = express()

### Authentication

This routine is called for all request to the API. It is reponsible for
authenticating the user by validating the `api\_key`. It then sets some request
session variables so they become accessible throughout the entire system during
the rquest.

In future versions of the API this routine will also check the request quota and
blocking the user if the quota is full.

    app.use '/', (req, res, next) ->

      key = req.query.api_key

      return res.json 403, message: 'API key missing' if not key
      return res.json 401, message: 'API key invalid' if not apiKeys[key]

      req.key = key
      req.usr = apiKeys[key]

      next()

### Configuration

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

### Error handling

This is the error handler. All errors passed to `next` or exceptions ends up
here. We set the status code to `500` if it is not already defined in the
`Error` object. We then print the error mesage and stack trace to the console
for debug purposes.

Before returning a response to the user the request method is check. HEAD
requests shall not contain any body – this applies for errors as well.

    app.use (err, req, res, next) ->
      res.status(err.status or 500)

      console.error err.message
      console.error err.stack

      return res.end() if req.method is 'HEAD'
      return res.json message: err.message or 'Ukjent feil'

This the fmous 404 Not Found handler. If no route configuration for the request
is found, it ends up here. We don't do much fancy about it – just a standard
error message and HTTP status code.

    app.use (req, res) -> res.json 404, message: "Resurs ikke funnet"

### API keys

This is the dirty part. Here are all the keys to the kingdom. These will be
moved to the database and retrieved when the server starts. Just need to find
the time to do it.

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

## GET /

    app.get '/', (req, res) ->
      res.json message: 'Here be dragons'

## GET /system

Hsssssj!!! Don't tell anyone about the secret system API endpoint!

    app.get '/system', system.info

## GET /CloudHealthCheck

> So...You’re seeing the dotCloud active health check looking to make sure that
> your service is up. There is no way for you to disable it, but you can prevent
> it and you can handle it [1]!

[1] [dotCloud](http://docs.dotcloud.com/tutorials/more/cloud-health-check/)

    app.get '/CloudHealthCheck', system.check

## GET /objekttyper

    app.get '/objekttyper', (req, res, next) ->
      res.json 200, ['turer', 'steder', 'områder', 'grupper', 'arrangementer', 'bilder']

## ALL /{collection}

    app.param 'collection', collection.param
    app.all '/:collection', (req, res, next) ->
      switch req.method
        when 'OPTIONS' then collection.options req, res, next
        when 'HEAD', 'GET' then collection.get req, res, next
        when 'POST' then collection.post req, res, next
        when 'PUT'  then collection.put req, res, next
        when 'PATCH' then collection.patch req, res, next
        else res.json 405, message: 'HTTP method not supported'

## ALL /{collection}/{objectid}

    app.param 'objectid', document.param
    app.all '/:collection/:objectid', (req, res, next) ->
      switch req.method
        when 'OPTIONS' then document.options req, res, next
        when 'HEAD', 'GET' then document.get req, res, next
        when 'PUT' then document.put req, res, next
        when 'PATCH' then document.patch req, res, next
        when 'DELETE' then document.delete req, res, next
        else res.json 405, message: 'HTTP method not supported'

## Start

Ok, so if the server is running in stand-alone mode i.e. there is not
`module.parent` then continue with starting the databse and listening to a port.

    if not module.parent
      require('./db/redis')
      require('./db/mongo').once 'ready', ->
        console.log 'Database is open...'

        app.listen app.get('port'), ->
          console.log "Server is listening on port #{app.get('port')}"

However, if there is a `module.parent` don't do all the stuff above. This means
that there is some program that is including the server from it, e.g a test, and
hence it should not listen to a port for incomming connections and rather just
return the application instance so that we can do some testing on it.

    else
      module.exports = app


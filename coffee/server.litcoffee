    raven       = require 'raven'
    sentry      = require './db/sentry'
    express     = require 'express'

    auth        = require './helper/auth'

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

    app.use '/', (req, res, next) ->
      return next() if req.originalUrl.substr(0, 17) is '/CloudHealthCheck'

      auth.check req.query.api_key, (err, user) ->
        if user
          res.set 'X-RateLimit-Limit', user.limit
          res.set 'X-RateLimit-Remaining', user.remaining
          res.set 'X-RateLimit-Reset', user.reset

        req.user = user

        return next err if err

        next()

### Configuration

    app.use(express.favicon())
    app.use(express.logger(':date :remote-addr - :method :url :status :res[content-length] - :response-time ms')) if not process.env.SILENT
    app.use(express.compress())
    app.use(express.json())
    app.disable('x-powered-by')
    app.set 'port', process.env.APP_PORT or 8080
    app.use(app.router)

### Error handling

Before handling the error ours self make sure that it is propperly logged in
Sentry by using the express/connect middleware.

    app.use raven.middleware.express sentry

All errors passed to `next` or exceptions ends up here. We set the status code
to `500` if it is not already defined in the `Error` object. We then print the
error mesage and stack trace to the console for debug purposes.

Log 401 Unauthorized (warning) and 403 Forbidden (notice) errors to Sentry to
enhance debugging and oversight as Nasjonal Turbase gets more used.

Before returning a response to the user the request method is check. HEAD
requests shall not contain any body – this applies for errors as well.

    app.use (err, req, res, next) ->
      res.status err.status or 500

      if res.statusCode is 401
        sentry.captureMessage "Invalid API-key #{req.query.api_key}",
          level: 'warning'
          extra: sentry.parseRequest req, user: req.user

      if res.statusCode is 403
        sentry.captureMessage "Rate limit exceeded for #{req.user.tilbyder}",
          level: 'notice'
          extra: sentry.parseRequest req, user: req.user

      if res.statusCode >= 500
        console.error err.message
        console.error err.stack

      return res.end() if req.method is 'HEAD'
      return res.json message: err.message or 'Ukjent feil'

This the fmous 404 Not Found handler. If no route configuration for the request
is found, it ends up here. We don't do much fancy about it – just a standard
error message and HTTP status code.

    app.use (req, res) -> res.json 404, message: "Resurs ikke funnet"

## GET /

    app.get '/', (req, res) ->
      res.json message: 'Here be dragons'

## GET /CloudHealthCheck

> So...You’re seeing the dotCloud active health check looking to make sure that
> your service is up. There is no way for you to disable it, but you can prevent
> it and you can handle it [1]!

[1] [dotCloud](http://docs.dotcloud.com/tutorials/more/cloud-health-check/)

    app.all '/CloudHealthCheck', system.check

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
        else res.json 405, message: "HTTP Method #{req.method.toUpperCase()} Not Allowed"

## ALL /{collection}/{objectid}

    app.param 'objectid', document.param
    app.options '/:collection/:ojectid', document.options
    app.all '/:collection/:objectid', document.all, (req, res, next) ->
      switch req.method
        when 'HEAD', 'GET' then document.get req, res, next
        when 'PUT' then document.put req, res, next
        when 'PATCH' then document.patch req, res, next
        when 'DELETE' then document.delete req, res, next
        else res.json 405, message: "HTTP Method #{req.method.toUpperCase()} Not Allowed"

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


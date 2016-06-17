    require 'newrelic' if process.env.NODE_ENV is 'production'

    raven       = require 'raven'
    sentry      = require './db/sentry'
    express     = require 'express'
    compression = require 'compression'
    bodyParser  = require 'body-parser'
    responseTime= require 'response-time'

    auth        = require './helper/auth'
    collections = require('./helper/schema').types

    system      = require './system'
    collection  = require './collection'
    document    = require './document'

## Init

    app = module.exports = express()

### Configuration

    app.disable 'x-powered-by'
    app.disable 'etag'

    app.use compression()
    app.use responseTime()

    app.use bodyParser.json extended: true, limit: '10mb'

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

## GET /

    app.get '/', (req, res) ->
      res.json message: 'Here be dragons'

## GET /favicon

    app.get '/favicon.ico', (req, res) ->
      res.set 'Content-Type': 'image/x-icon'
      res.status(200).end()

## GET /CloudHealthCheck

> So...You’re seeing the dotCloud active health check looking to make sure that
> your service is up. There is no way for you to disable it, but you can prevent
> it and you can handle it [1]!

[1] [dotCloud](http://docs.dotcloud.com/tutorials/more/cloud-health-check/)

    app.all '/CloudHealthCheck', system.check

## GET /objekttyper

    app.get '/objekttyper', (req, res, next) ->
      res.json collections

## ALL /{collection}

    app.param 'collection', collection.param
    app.all '/:collection', (req, res, next) ->
      switch req.method
        when 'OPTIONS' then collection.options req, res, next
        when 'HEAD', 'GET' then collection.get req, res, next
        when 'POST' then collection.post req, res, next
        else res.status(405).json message: "HTTP Method #{req.method.toUpperCase()} Not Allowed"

## ALL /{collection}/{objectid}

    app.param 'objectid', document.param
    app.options '/:collection/:ojectid', document.options
    app.all '/:collection/:objectid', document.all, (req, res, next) ->
      switch req.method
        when 'HEAD', 'GET' then document.get req, res, next
        when 'PUT' then document.put req, res, next
        when 'PATCH' then document.patch req, res, next
        when 'DELETE' then document.delete req, res, next
        else res.status(405).json message: "HTTP Method #{req.method.toUpperCase()} Not Allowed"

## 404 handling

This the fmous 404 Not Found handler. If no route configuration for the request
is found, it ends up here. We don't do much fancy about it – just a standard
error message and HTTP status code.

    app.use (req, res) -> res.status(404).json message: "Resurs ikke funnet"

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

## Start

Start the server listening on the port defined in the `VIRTUAL_PORT` environment
variable or the default port `8080` if the server is running in stand alone
mode.

    if not module.parent

Wait for Redis and MongoDB to become aviable before accepting connections on the
server port.

      require('./db/redis')
      require('./db/mongo').once 'ready', ->
        console.log 'Database is open...'

        app.listen process.env.VIRTUAL_PORT || 8080, ->
          console.log "Server is listening on port #{process.env.VIRTUAL_PORT || 8080}"

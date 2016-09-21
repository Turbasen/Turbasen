Client = require('raven').Client

Client.prototype.captureDocumentError = (req, err) ->
  @captureMessage "#{req.type}: #{err.details[0].message}",
    level: 'warning'
    extra: req: req, err: err

module.exports = new Client process.env.SENTRY_DNS
module.exports.parseRequest = (req, kwargs = {}) ->
  kwargs.http =
    method: req.method
    query: req.query
    headers: req.headers
    data: req.body
    url: req.originalUrl

  kwargs

if process.env.NODE_ENV isnt 'development'
  module.exports.patchGlobal (id, err) ->
    # coffeelint: disable=no_debugger
    console.error 'Uncaught Exception'
    console.error err.message
    console.error err.stack
    # coffeelint: enable=no_debugger

    process.exit 1


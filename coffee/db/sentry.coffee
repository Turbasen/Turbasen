Client = require('raven').Client

Client.prototype.captureDocumentError = (req, err) ->
  @captureMessage "#{req.type}: #{err.details[0].message}",
    level: 'warning'
    extra: req: req, err: err

module.exports = new Client process.env.SENTRY_DNS

module.exports.patchGlobal (id, err) ->
  console.error 'Uncaught Exception'
  console.error err.message
  console.error err.stack
  process.exit 1


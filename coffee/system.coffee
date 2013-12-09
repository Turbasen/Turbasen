"use strict"

os = require 'os'

exports.info = (req, res, next) ->
  return res.status(403).end() if req.usr isnt 'DNT'

  res.json 200,
    app:
      uptime: process.uptime()
      memory: process.memoryUsage()
    os:
      uptime: os.uptime()
      loadavg: os.loadavg()
      totalmem: os.totalmem()
      freemem: os.freemem()

exports.gc = (req, res, next) ->
  return res.status(403).end() if req.usr isnt 'DNT'

  global.gc() if typeof global.gc is 'function'
  res.end()


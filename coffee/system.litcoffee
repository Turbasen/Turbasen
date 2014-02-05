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

exports.check = (req, res, next) ->
  return res.status(403).end() if req.usr not in ['DNT', 'Pingdom']

  status = 200
  service = {}
  serviceCount = 2
  callbackCount = 0

  ret = ->
    return if ++callbackCount > 1
    status = 500 if Object.keys(service).length isnt serviceCount
    res.json status, service

  req.cache.redis.info (err, info) ->
    service.Redis = {}

    if err
      status = 500
      service.Redis.status = 0
      service.Redis.message = err.toString()
    else
      service.Redis.status = 1
      service.Redis.message = info.toString().split("\r\n").sort()

      ret() if Object.keys(service).length is serviceCount

  req.cache.mongo.command {dbStats:true}, (err, info) ->
    service.Mongo = {}

    if err
      status = 500
      service.Mongo.status = 0
      service.Mongo.message = err.toString()
    else
      service.Mongo.status = 1
      service.Mongo.message = info

    ret() if Object.keys(service).length is serviceCount

    setTimeout ret, 2000


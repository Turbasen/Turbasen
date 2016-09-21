request   = require 'supertest'
assert    = require 'assert'

req = request require '../../coffee/server'

describe '/favicon.ico', ->
  it 'should return 200 OK for GET request', ->
    req.get '/favicon.ico'
      .expect 200
      .expect 'Content-Type', 'image/x-icon'

describe '/CloudHealthCheck', ->
  it 'should return 200 OK for GET request', ->
    req.get '/CloudHealthCheck'
      .expect 200
      .expect message: 'System OK'

  it 'should return 200 OK for HEAD request', ->
    req.get '/CloudHealthCheck'
      .expect 200

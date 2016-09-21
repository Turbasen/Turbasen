request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

it 'should return 404 Not Found for missing resources', ->
  req.get '/this/is/not/found'
    .expect 404
    .expect message: 'Resurs ikke funnet'

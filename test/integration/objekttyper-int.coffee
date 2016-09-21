request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

it 'should return list of avaiable object types', ->
  req.get('/objekttyper?api_key=dnt')
    .expect 200
    .expect [
      'arrangementer'
      'bilder'
      'grupper'
      'lister'
      'områder'
      'steder'
      'turer'
    ]

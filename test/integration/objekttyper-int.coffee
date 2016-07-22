request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

it 'should return list of avaiable object types', (done) ->
  req.get('/objekttyper?api_key=dnt')
    .expect 200
    .expect (res) ->
      assert.deepEqual res.body, [
        'arrangementer'
        'bilder'
        'grupper'
        'lister'
        'områder'
        'steder'
        'turer'
      ]
    .end done

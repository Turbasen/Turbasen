request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

it 'should return list of avaiable object types', (done) ->
  req.get('/objekttyper?api_key=dnt').expect(200).end (err, res) ->
    assert.ifError err
    assert.deepEqual res.body, [
      'turer', 'steder', 'områder', 'grupper', 'arrangementer', 'bilder'
    ]
    done()

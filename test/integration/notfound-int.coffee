request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

it 'should return 404 Not Found for missing resources', (done) ->
  req.get('/this/is/not/found').expect(404).end (err, res) ->
    assert.ifError err
    assert.equal res.body.message, 'Resurs ikke funnet'
    done()


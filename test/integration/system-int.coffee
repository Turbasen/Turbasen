request   = require 'supertest'
assert    = require 'assert'

req = req = request require '../../coffee/server'

describe '/CloudHealthCheck', ->
  it 'should return status for MongoDB and Redis', (done) ->
    key = 'b523ceb5e16fb92b2a999676a87698d1'
    req.get('/CloudHealthCheck?api_key=' + key).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.deepEqual Object.keys(res.body), ['Redis', 'Mongo']
      assert.equal res.body.Redis.status, 1
      assert.equal res.body.Mongo.status, 1
      done()


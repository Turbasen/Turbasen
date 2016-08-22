request = require 'supertest'
assert  = require 'assert'
async   = require 'async'

req     = request require './../../coffee/server'

oid     = null
doc     = JSON.parse JSON.stringify require './../data/tur.json'
delete doc._id
delete doc.endret
delete doc.checksum

beforeEach ->
  req.post "/turer?api_key=dnt"
    .send doc
    .expect 201
    .expect (res) ->
      oid = res.body.document._id
      assert.deepEqual val, res.body.document[key] for key, val of doc

it 'should be able to read document', ->
  req.get "/turer/#{oid}?api_key=dnt"
    .expect 200
    .expect (res) ->
      assert.deepEqual val, res.body[key] for key, val of doc

it 'should be able to update document', ->
  req.patch "/turer/#{oid}?api_key=dnt"
    .send navn: 'Nytt navn'
    .expect 200
    .expect (res) ->
      assert.equal res.body.document.navn, 'Nytt navn'

it 'should be able to delete document', ->
  req.delete "/turer/#{oid}?api_key=dnt"
    .expect 204
    .expect {}

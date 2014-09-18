request = require 'supertest'
assert  = require 'assert'
async   = require 'async'

req     = request require './../../coffee/server'

it 'should reindex all documents in collection', (done) ->
  visited = []
  count = 0
  skip = 0

  async.doWhilst (doWhilstNext) ->
    req.get "/steder?tag=Hytte&api_key=dnt&skip=#{skip}"
      .expect 200
      .end (err, res) ->
        assert.ifError err
        assert.equal res.body.total, 120

        skip += res.body.count
        count = res.body.count

        async.each res.body.documents, (doc, eachNext) ->
          assert doc not in visited

          req.get "/steder/#{doc._id}?api_key=dnt"
            .end (err, res) ->
              assert.ifError err

              if doc.status is 'Slettet'
                assert.equal res.statusCode, 404
              else
                assert.equal doc._id, res.body._id

              visited.push doc._id
              eachNext()

        , doWhilstNext
  , ->
    count > 0
  , (err) ->
    assert.ifError err
    assert.equal visited.length, 120
    done()

it 'should get documents updated since', (done) ->
  req.get "/steder?tag=Hytte&skip=0&after=1387204002&api_key=dnt"
    .expect 200
    .end (err, res) ->
      assert.ifError err
      assert.equal res.body.total, 29
      done()

it 'should get no documents updated since', (done) ->
  req.get "/steder?tag=Hytte&skip=0&after=1488404002&api_key=dnt"
    .expect 200
    .end (err, res) ->
      assert.ifError err
      assert.equal res.body.total, 0
      done()


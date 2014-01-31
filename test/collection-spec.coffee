"use strict"

ObjectID  = require('mongodb').ObjectID
request   = require 'supertest'
assert    = require 'assert'

req = cache = steder = null

before ->
  app     = module.parent.exports.app
  steder  = module.parent.exports.steder
  req     = request(app)
  cache   = app.get 'cache'

describe 'OPTIONS', ->
  it 'should return allowed http methods', (done) ->
    req.options('/steder?api_key=dnt').expect(200)
      .expect('Access-Control-Allow-Methods', 'HEAD, GET, POST, PATCH, PUT', done)

describe 'GET', ->
  url = '/steder?api_key=dnt'

  it 'should get the collection', (done) ->
    req.get(url)
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 20
        assert.equal res.body.count, 20
        assert.equal res.body.total, 120
        done()

  it 'should grant access for the 6 known collections', (done) ->
    cols = ['turer', 'steder', 'områder', 'grupper', 'bilder', 'aktiviteter']
    count = cols.length

    for col in cols
      req.get(url.replace('steder', col))
        .expect(200)
        .end (err, res) ->
          assert.ifError(err)
          done() if --count is 0

  it 'should restrict access to unknown collections', (done) ->
    cols = ['system.test', 'test', 'admin', '_test', 'æøå']
    count = cols.length

    for col in cols
      req.get(url.replace('steder', col))
        .expect(404)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.message, 'Objekttype ikke funnet'
          done() if --count is 0

  it 'should return a limited set of document properties', (done) ->
    req.get(url)
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)

        for doc in res.body.documents
          assert.equal Object.keys(doc).length, 5
          assert.equal typeof doc._id, 'string'
          assert.equal typeof doc.tilbyder, 'string'
          assert.equal typeof doc.endret, 'string'
          assert.equal typeof doc.status, 'string'
          assert.equal typeof doc.navn, 'string'

        done()

  it 'should handle improper formated parameters', (done) ->
    req.get(url + '&limit=foo&offset=bar')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 20
        done()

  it 'should limit number of items correctly', (done) ->
    req.get(url + '&limit=5')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 5
        done()

  it 'should limit limit to max 50', (done) ->
    req.get(url + '&limit=100')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 50
        done()

  it 'should offset items correctly', (done) ->
    req.get(url + '&limit=5')
      .expect(200)
      .end (err, res1) ->
        assert.ifError(err)

        req.get(url + '&limit=1&skip=4')
          .expect(200)
          .end (err, res2) ->
            assert.ifError(err)
            assert.deepEqual res1.body.documents[4], res2.body.documents[0]
            done()

  it 'should get items after specified date', (done) ->
    req.get(url + '&after=2014-01-01')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)

        assert.equal res.body.count, 2
        assert.equal res.body.total, 2

        for doc in res.body.documents
          assert doc.endret >= '2014-01-01'

        done()

  it 'should parse milliseconds to ISO datestamp', (done) ->
    req.get(url + '&after=' + new Date('2014-01-01').getTime())
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)

        assert.equal res.body.count, 2
        assert.equal res.body.total, 2

        for doc in res.body.documents
          assert doc.endret >= '2014-01-01'

        done()

  it 'should handle invalid after parameter', (done) ->
    req.get(url + '&after=' + ['foo', 'bar'])
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal typeof res.body.message, 'undefined'
        done()

  it 'should handle empty after parameter', (done) ->
    req.get(url + '&after=')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.documents.length, 20
        done()

  it 'should list items with given tag in first position', (done) ->
    req.get(url + '&tag=Hytte')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.total, 120
        done()

  # @TODO(starefossen) add normal poi to data set
  it 'should list items with not given tag in first position', (done) ->
    req.get(url + '&tag=!Hytte')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.total, 0
        done()

  it 'should list items connected with given group', (done) ->
    req.get(url + '&gruppe=52407f3c4ec4a1381500025d')
      .expect(200)
      .end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.total, 26
        done()

  describe 'param bbox', ->
    it 'should list items within bounding box', (done) ->
      req.get(url + '&bbox=5.456085205078125,60.77559056838706,6.5224456787109375,61.03601470372404')
        .expect(200)
        .end (err, res) ->
          assert.ifError(err)
          assert.equal res.body.count, 7
          done()

  describe 'param privat.*', ->
    it 'should filter on private string attribute', (done) ->
      req.get(url + '&privat.secret=0905c600ca377ac51438fa4f7e403d8d')
        .expect 200
        .expect 'Count-Total', '1'
        .end (err, res) ->
          assert.ifError err
          assert.equal res.body.documents[0].navn, '0bd623dc1855b1f4f564d7bae362cd11'
          done()

    it 'should filter on private integer attribute', (done) ->
      req.get(url + '&privat.opprettet_av.id=1234')
        .expect 200
        .expect 'Count-Total', '19', done

    it 'should only get own documents', (done) ->
      req.get(url + '&privat.opprettet_av.id=https://openid.provider.com/user/abcd123')
        .expect 200
        .expect 'Count-Total', '21'
        .end (err, res) ->
          assert.ifError err
          assert.equal doc.tilbyder, 'DNT' for doc in res.body.documents
          done()

describe 'HEAD', ->
  url = '/steder?api_key=dnt'

  it 'should only get http header for collection resource', (done) ->
    req.head(url).expect(200)
      .expect('Count-Return', /^[0-9]+$/)
      .expect('Count-Total', /^[0-9]+$/)
      .end (err, res) ->
        assert.ifError(err)
        assert.deepEqual(res.body, {})
        done()

describe 'POST', ->
  url = '/steder?api_key=dnt'

  doc = null

  beforeEach ->
    doc = JSON.parse(JSON.stringify(steder[13]))
    delete doc._id
    delete doc.tilbyder
    delete doc.endret
    delete doc.checksum

  it 'should insert single object in collection and return ObjectID', (done) ->
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.count, 1
      assert.equal typeof res.body.document, 'object'
      assert.equal typeof res.body.document._id, 'string'

      id = new ObjectID(res.body.document._id)
      cache.getCol('steder').findOne _id: id, (err, d) ->
        assert.ifError(err)
        assert.equal typeof d, 'object'
        assert.deepEqual d[key], val for key, val of doc
        done()

  it 'should override tilbyder, endret and checksum fields', (done) ->
    doc.tilbyder = 'MINAPP'
    doc.endret   = new Date().toISOString()
    doc.checksum = '332dcf1830ec8e2c9bdc574b29515047'

    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)

      doc._id = new ObjectID(res.body.document._id)
      cache.getCol('steder').findOne _id: doc._id, (err, d) ->
        assert.ifError(err)

        ignore = ['tilbyder', 'endret', 'checksum']
        assert.notEqual d[key], val for key, val of doc when key in ignore
        assert.deepEqual d[key], val for key, val of doc when key not in ignore
        done()

  it 'should handle rapid requests to collection', (done) ->
    this.timeout(5000)

    count = 100
    for i in [0..count]
      doc = JSON.parse(JSON.stringify(steder[i]))
      delete doc._id
      delete doc.tilbyder
      delete doc.endret
      delete doc.checksum

      req.post(url).send(doc).expect(201).end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.count, 1
        assert.equal typeof res.body.document, 'object'
        done() if --count is 0

  it 'should convert _id to ObjectID if provided with one', (done) ->
    doc._id = new ObjectID()
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.document._id, doc._id
      done()

  it 'should update existing document', (done) ->
    doc = JSON.parse(JSON.stringify(steder[15]))
    doc.navn = 'En oppdatert tur'
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)

      cache.getCol('steder').findOne _id: new ObjectID(doc._id), (err, d) ->
        assert.ifError(err)
        ignore = ['_id', 'tilbyder', 'endret', 'checksum']
        assert.deepEqual d[key], val for key, val of doc when key not in ignore
        done()

  it 'should add new documents to cache', (done) ->
    req.post(url).send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      cache.getForType 'steder', res.body.document._id, (err, d) ->
        # @TODO undefined values
        assert.equal d[key], val for key,val of cache.filterData('steder', doc) when val
        done()

  it 'should warn about missing lisens field', (done) ->
    delete doc.lisens
    req.post('/steder?api_key=dnt').send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert.deepEqual res.body.warnings, [{
        resource: 'steder'
        field: 'lisens'
        value: 'CC BY-ND-NC 3.0 NO'
        code: 'missing_field'
      }]
      done()

  it 'should warn about missing status field', (done) ->
    delete doc.status
    req.post('/steder?api_key=dnt').send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert res.body.warnings, [{
        resource: 'steder'
        field: 'status'
        value: 'Kladd'
        code: 'missing_field'
      }]
      done()

  it 'should return error for missing request body', (done) ->
    req.post('/steder?api_key=dnt').expect(400, done)

  it 'should return error if request body is an array', (done) ->
    #doc = new Generator('steder').gen()
    req.post('/steder?api_key=dnt').send([doc]).expect(422, done)

describe 'PUT', ->
  it 'should not be implemeted', (done) ->
    req.put('/steder?api_key=dnt')
      .expect(501, done)

describe 'PATCH', ->
  it 'should not be implemented', (done) ->
    req.patch('/steder?api_key=dnt')
      .expect(501, done)

describe 'DELETE', ->
  it 'should not be able to DELETE', (done) ->
    req.del('/steder?api_key=dnt')
      .expect(405, done)


request     = require 'supertest'
assert      = require 'assert'
async       = require 'async'

ObjectID    = require('mongodb').ObjectID
Collection  = require('mongodb').Collection

Document    = require '../../../coffee/model/Document'
cache       = require '../../../coffee/helper/cache'
redis       = require '../../../coffee/db/redis'
mongo       = require '../../../coffee/db/mongo'

data =
  grupper : require '../../data/gruppe.json'
  bilder  : require '../../data/bilde.json'
  turer   : require '../../data/tur.json'
  områder : require '../../data/omrade.json'
  steder  : require '../../data/sted.json'

now = new Date().toISOString()

d = doc = steder = null

before -> steder = module.parent.exports.steder

describe 'New', ->
  beforeEach (done) ->
    doc = new Document 'steder', null
    .once 'error', assert.ifError
    .once 'ready', done

  describe 'Doc()', ->
    it 'should create new Doc object', ->
      assert doc instanceof Document

    it 'should instanciate Doc properties', ->
      assert doc.db instanceof Collection
      assert.equal doc.chit, false
      assert.equal doc.id, null
      assert.equal doc.type, 'steder'
      assert.deepEqual doc.data, {}

    it 'should throw an error for missing type parameter', ->
      assert.throws ->
        new Document()
      , /Missing Doc type param/

    it 'should throw an error for missing user parameter', ->
      assert.throws ->
        new Document 'steder'
      , /Missing or invalid ID param/

  describe '#exists()', ->
    it 'should not exist', ->
      assert.equal doc.exists(), false

  describe '#getId()', ->
    it 'should return null', ->
      assert.equal doc.getId(), null

  describe '#wasCacheHit()', ->
    it 'should return false by default', ->
      assert.equal doc.wasCacheHit(), false

  describe '#isModifiedSince()', ->
    Date.prototype.toUnixTime = -> Math.floor(@getTime()/1000)

    methods = [
      'toString'
      'toUTCString'
      'toISOString'
      'getTime'
      'toUnixTime'
    ]

    beforeEach ->
      doc.data.endret = new Date('2013-12-16T14:25:47.966Z')

    it 'sould return false for no data.endret', ->
      delete doc.data.endret
      assert.equal doc.isModifiedSince(new Date()), false
      assert.equal doc.isNotModifiedSince(new Date()), false

    it 'should return false for no test date', ->
      assert.equal doc.isModifiedSince(undefined), false
      assert.equal doc.isNotModifiedSince(undefined), false

    it 'should return false for invalid test date', ->
      assert.equal doc.isModifiedSince('invalid'), false
      assert.equal doc.isNotModifiedSince('invalid'), false

    it 'should return correctly for later test date', ->
      d = new Date('2014-12-16T14:25:47.966Z')
      async.each methods, (method) ->
        assert.equal doc.isModifiedSince(d[method]()), false
        assert.equal doc.isNotModifiedSince(d[method]()), true

    it 'should return correctly for equal test date', ->
      d = new Date('2013-12-16T14:25:47.966Z')
      async.each methods, (method) ->
        assert.equal doc.isModifiedSince(d[method]()), false
        assert.equal doc.isNotModifiedSince(d[method]()), true

    it 'should ignore milliseconds (HTTP dates)', ->
      d = new Date('2013-12-16T14:25:47.001Z')
      async.each methods, (method) ->
        assert.equal doc.isModifiedSince(d[method]()), false
        assert.equal doc.isNotModifiedSince(d[method]()), true

    it 'should return correctly for smaller test date', ->
      d = new Date('2012-12-16T14:25:47.966Z')
      async.each methods, (method) ->
        assert.equal doc.isModifiedSince(d[method]()), true
        assert.equal doc.isNotModifiedSince(d[method]()), false

  describe '#isMatch()', ->
    checksum = '7054837d420a83c2d70749dd09ef71e341079465'

    beforeEach ->
      doc.data.checksum = checksum

    it 'should return false for no data.checksum', ->
      delete doc.data.checksum
      assert.equal doc.isMatch("\"#{checksum}\""), false

    it 'should reuturn false for no test checksum', ->
      assert.equal doc.isMatch(), false

    it 'should reuturn false for inequal test checksum', ->
      assert.equal doc.isMatch("\"#{checksum + 'a'}\""), false

    it 'should reuturn true for equal test checksum', ->
      assert.equal doc.isMatch("\"#{checksum}\""), true

    it 'should return true for special value "*"', ->
      assert.equal doc.isMatch('*'), true

  describe '#isNoneMatch()', ->
    checksum = '7054837d420a83c2d70749dd09ef71e341079465'

    beforeEach ->
      doc.data.checksum = checksum

    it 'should return false for no test checksum', ->
      assert.equal doc.isNoneMatch(), false

    it 'should return true for no data.checksum', ->
      delete doc.data.checksum
      assert.equal doc.isNoneMatch("\"#{checksum}\""), true

    it 'should return true for inequal test checksum', ->
      assert.equal doc.isNoneMatch("\"#{checksum + 'a'}\""), true

    it 'should return false for equal test checksum', ->
      assert.equal doc.isNoneMatch("\"#{checksum}\""), false

    it 'should return true for special value "*"', ->
      assert.equal doc.isNoneMatch('*'), true

  describe '#get()', ->
    it 'should return empty data', ->
      assert.deepEqual doc.get(), {}

    it 'should return undefined for unset data key', ->
      assert.equal doc.get('navn'), undefined

  describe '#getFull()', ->
    it 'should return error for non existing document', (done) ->
      doc.getFull {}, (err, d) ->
        assert /Document doesnt exists/.test err
        assert.equal d, undefined
        done()

    it 'should throw error for non existing document and no callback', ->
      assert.throws ->
        doc.getFull {}
      , /Document doesnt exists/

  describe '#getExpanded()', ->
    it 'returns unexpanded object'
    it 'ignores invalid collection keys'
    it 'returns single expanded object'
    it 'returns multiple expanded objects'

  describe '#insert()', ->
    it 'should insert new document without _id in database', (done) ->
      d = JSON.parse JSON.stringify steder[39]
      delete d._id
      doc.insert d, (err, warn, doc1) ->
        assert.ifError err
        mongo.steder.findOne _id: doc1._id, (err, doc2) ->
          assert.ifError err
          assert.deepEqual doc1, doc2
          done()

    it 'should insert new document with _id in database', (done) ->
      d = JSON.parse JSON.stringify steder[40]
      d._id = new ObjectID().toString()
      doc.insert d, (err, warn, doc1) ->
        assert.ifError err
        mongo.steder.findOne _id: new ObjectID(d._id), (err, doc2) ->
          assert.ifError err
          assert.deepEqual doc1, doc2
          done()

    it 'should insert new document in cache', (done) ->
      d = JSON.parse JSON.stringify steder[41]
      delete d._id
      doc.insert d, (err, warn, doc1) ->
        assert.ifError err
        redis.hgetall "steder:#{doc1._id}", (err, doc2) ->
          assert.ifError err

          doc2 = cache.arrayify 'steder', doc2

          for key, val of doc2 when key not in ['checksum']
            assert.deepEqual val, (d[key] or [])

          done()

    # it 'should aggregate db insert statistics'

    describe '#replace()', ->
      it 'should return error for non existing document', (done) ->
        doc.replace {}, (err, warn, docData) ->
          assert /Document doesnt exists/.test err
          assert.equal warn, undefined
          assert.equal docData, undefined
          done()

    describe '#update()', ->
      it 'should return error for non existing document', (done) ->
        doc.update {}, (err, warn, docData) ->
          assert /Document doesnt exists/.test err
          assert.equal warn, undefined
          assert.equal docData, undefined
          done()

    describe '#delete()', ->
      it 'should return error for non existing document', (done) ->
        doc.delete (err, warn, docData) ->
          assert /Document doesnt exists/.test err
          assert.equal warn, undefined
          assert.equal docData, undefined
          done()

describe 'Existing', ->
  beforeEach (done) ->
    doc = new Document 'steder', '52407fb375049e5615000008'
    .once 'error', assert.ifError
    .once 'ready', done

  it 'should be cache miss', ->
    assert.equal doc.chit, false

  it 'should be cache hit for sequential requests', (done) ->
    new Document 'steder', '52407fb375049e5615000008'
    .once 'error', assert.ifError
    .once 'ready', ->
      assert.equal @chit, true
      done()

  # it 'should aggregate cache hit statistics'
  # it 'should aggregate cache miss statistics'

  it 'should initalize document instance correctly', ->
    assert.equal doc.id.toString(), '52407fb375049e5615000008'
    assert.deepEqual doc.data,
      endret: '2013-12-16T14:19:53.693Z'
      checksum: '6fa48eca48702c171c4bb6ef5e95dbbd'
      tilbyder: 'DNT'
      status: 'Offentlig'
      lisens: 'CC BY 4.0'
      navn: 'd48f6eb3609490dadc7ac233136f95c1'
      områder: ['52408144e7926dcf1500000a', '52408144e7926dcf1500000e']
      bilder: [
        '5242a065f92e7d7112011307'
        '5242a066f92e7d711201fd7e'
        '5242a065f92e7d71120119fd'
      ]
      grupper: ['52407f3c4ec4a13815000246']

  describe '#exists()', ->
    it 'should exist', ->
      assert.equal doc.exists(), true

  describe '#getId()', ->
    it 'should return a ObjectID', ->
      assert doc.getId() instanceof ObjectID

    it 'should return correct ObjectID value', ->
      assert.equal doc.getId().toString(), '52407fb375049e5615000008'

  describe '#get()', ->
    it 'should return all cached document properties', ->
      assert.equal Object.keys(doc.get()).length, 9

    it 'should only return data for selected key', ->
      assert.equal doc.get('navn'), 'd48f6eb3609490dadc7ac233136f95c1'

    it 'should not return data for nonexisting key', ->
      assert.equal doc.get('notexisting'), undefined

  describe '#getFull()', ->
    it 'should return all data for existing document in database', (done) ->
      doc.getFull {}, (err, mongoData) ->
        assert.ifError err
        assert.equal Object.keys(mongoData).length, 14
        assert.equal typeof mongoData.privat, 'object'
        done()

    it 'should only return selected properties', (done) ->
      doc.getFull navn: true, lisens: true, (err, mongoData) ->
        assert.ifError err
        assert.equal Object.keys(mongoData).length, 3 # this includes doc._id
        done()

    it 'should return a cursor object if no callback is specified', ->
      cursor = doc.getFull {}
      assert cursor.stream instanceof Function
      assert cursor.toArray instanceof Function

    # it 'should aggregate db get statistics'

  describe '#insert()', ->
    it 'should return error for existing document', (done) ->
      doc.insert {}, (err, warn, docData) ->
        assert /Document already exists/.test err
        assert.equal warn, undefined
        assert.equal docData, undefined
        done()

    it 'should return error for deleted document', (done) ->
      doc.data.status = 'Slettet'
      doc.insert {}, (err, warn, docData) ->
        assert /Document is deleted/.test err
        assert.equal warn, undefined
        assert.equal docData, undefined
        done()

    # it 'should aggregate db insert statistics'
    # it 'should add document to recent updated documents list'

  describe '#replace()', ->
    sted1 = sted2 = null

    beforeEach ->
      sted1 = JSON.parse JSON.stringify data.steder
      sted2 = JSON.parse JSON.stringify data.steder
      sted1._id = sted2._id = doc.id.toString()

    it 'should replace data for document in database', (done) ->
      doc.replace sted1, (err, warn) ->
        assert.ifError err
        assert.deepEqual warn, []

        doc.getFull {}, (err, doc) ->
          assert.ifError err

          # This is auto converted to string over HTTP
          doc._id = doc._id.toString()

          ignore = ['checksum', 'endret']
          for key, val of sted2 when key not in ignore
            assert.deepEqual doc[key], val

          for key, val of sted2 when key in ignore
            assert.notEqual doc[key], val

          done()

    it 'should replace data for document in cache', (done) ->
      doc.replace sted1, (err, warn) ->
        assert.ifError err
        assert.deepEqual warn, []

        ignore = ['checksum', 'endret']
        for key, val of doc.get() when key not in ignore
          assert.deepEqual val, sted2[key]

        for key, val of doc.get() when key in ignore
          assert.notEqual val, sted2[key]

        done()

    # it 'should aggregate db update statistics'
    # it 'should add document to recent updated documents list'

  describe '#update()', ->
    query = null

    beforeEach ->
      query =
        $set:
          checksum: 'Foo', endret: 'Bar'
          bilder: ['530b4183dbd6386e051cd740', '530b4183dbd6386e051cd741']
        $unset: navn: ''
        $push:
          steder: '530b4183dbd6386e051cd742'
          grupper: $each: [
            '530b4183dbd6386e051cd743'
            '530b4183dbd6386e051cd744'
          ]
        $pull: områder: '52408144e7926dcf1500000e'

    it 'should update document data', (done) ->
      doc.update query, (err, warn, data1) ->
        assert.ifError err
        assert.deepEqual warn, []

        doc.getFull {}, (err, data2) ->
          assert.ifError err

          assert.deepEqual data1, data2
          assert.notEqual data1.checksum, '6fa48eca48702c171c4bb6ef5e95dbbd'
          assert.notEqual data1.endret, '2013-12-16T14:19:53.693Z'
          assert.equal data1.navn, undefined
          assert.deepEqual data1.steder, ['530b4183dbd6386e051cd742']
          assert.deepEqual data1.bilder, [
            '530b4183dbd6386e051cd740'
            '530b4183dbd6386e051cd741'
          ]
          assert.deepEqual data1.grupper, [
            '52407f3c4ec4a13815000246'
            '530b4183dbd6386e051cd743'
            '530b4183dbd6386e051cd744'
          ]
          assert.deepEqual data1.områder, ['52408144e7926dcf1500000a']

          done()

    it 'should update document data in cache', (done) ->
      doc.update query, (err, warn) ->
        assert.ifError err
        assert.deepEqual warn, []

        redis.hgetall "#{doc.type}:#{doc.id.toString()}", (err, data1) ->
          assert.ifError err
          data1 = cache.arrayify 'steder', data1

          assert.deepEqual data1, doc.get()
          assert.equal data1.tilbyder, 'DNT'
          assert.notEqual data1.checksum, '6fa48eca48702c171c4bb6ef5e95dbbd'
          assert.notEqual data1.endret, '2013-12-16T14:19:53.693Z'
          assert.equal data1.status, 'Offentlig'
          assert.equal data1.navn, undefined
          assert.deepEqual data1.områder, ['52408144e7926dcf1500000a']
          assert.deepEqual data1.steder, ['530b4183dbd6386e051cd742']
          assert.deepEqual data1.bilder, [
            '530b4183dbd6386e051cd740'
            '530b4183dbd6386e051cd741'
          ]
          assert.deepEqual data1.grupper, [
            '52407f3c4ec4a13815000246'
            '530b4183dbd6386e051cd743'
            '530b4183dbd6386e051cd744'
          ]

          done()

    # it 'should aggregate db update statistics'
    # it 'should add document to recent updated documents list'

  describe '#delete()', ->
    it 'should no longer exist', (done) ->
      doc.delete (err) ->
        assert.ifError err
        assert.equal doc.exists(), false
        done()

    it 'should have status = Slettet', (done) ->
      doc.delete (err) ->
        assert.ifError err
        assert.deepEqual Object.keys(doc.get()), ['status', 'endret']
        assert.deepEqual doc.get().status, 'Slettet'
        assert doc.get().endret instanceof Date
        done()

    it 'should set document as deleted in database', (done) ->
      doc.delete (err) ->
        assert.ifError err
        doc.db.findOne _id: doc.id, {}, (err, data1) ->
          assert.ifError err
          assert.deepEqual Object.keys(data1), ['_id', 'status', 'endret']
          assert.deepEqual data1.status, 'Slettet'
          assert data1.endret instanceof Date
          done()

    it 'should set document as deleted in cache', (done) ->
      doc.delete (err) ->
        redis.hgetall "#{doc.type}:#{doc.id.toString()}", (err, data1) ->
          assert.ifError err
          assert.deepEqual Object.keys(data1), ['status', 'endret']
          assert.deepEqual data1.status, 'Slettet'
          assert.deepEqual typeof data1.endret, 'string'
          done()

    # it 'should aggregate db delete statistics'

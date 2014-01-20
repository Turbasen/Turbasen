"use strict"

request   = require 'supertest'
assert    = require 'assert'
ObjectID  = require('mongodb').ObjectID

req = steder = null

before ->
  app = module.parent.exports.app
  steder = module.parent.exports.steder
  req = request(app)

url = (id, other) ->
  key = if other then '30ad3a3a1d2c7c63102e09e6fe4bb253' else 'dnt'
  "/steder/#{id}/?api_key=#{key}"

describe 'OPTIONS', ->
  it 'should return allowed http methods', (done) ->
    req.options(url(new ObjectID().toString())).expect(200)
      .expect('Access-Control-Allow-Methods', 'HEAD, GET, PUT, PATCH, DELETE', done)

describe 'GET', ->
  it 'should reject invalid object id', (done) ->
    req.get(url('abc123')).expect(400, done)

  it 'should return 404 for not existing document', (done) ->
    req.get(url(new ObjectID().toString())).expect(404).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.error, 'Document Not Found'
      done()

  it 'should return 404 for status=Slettet', (done) ->
    req.get(url('52d83333ea10e0fc14c9cecf')).expect(404, done)

  it 'should return document when status=Offentlig and tilbyder=DNT for DNT', (done) ->
    req.get(url('52407fb375049e5615000469')).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.tilbyder, 'DNT'
      assert.equal res.body.status, 'Offentlig'
      assert.equal res.body.navn, 'c818b09c3c51eb6f6f4ddc4c87a2a4f3'
      assert.deepEqual res.body.privat, secret: '21122df6e414ac844a6e80de1faf4871'
      done()

  it 'should return document when status=Kladd and tilbyder=DNT for DNT', (done) ->
    req.get(url('52d65048dfb20d629566667c')).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.tilbyder, 'DNT'
      assert.equal res.body.status, 'Kladd'
      assert.equal res.body.navn, '30f832f2a56d8ccf2e6356e0556d545f'
      assert.deepEqual res.body.privat, secret: '481d53830054097e48833a810827fc09'
      done()

  it 'should return document when status=Privat and tilbyder=DNT for DNT', (done) ->
    req.get(url('52d65b2544db971c94b2d949')).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.tilbyder, 'DNT'
      assert.equal res.body.status, 'Privat'
      assert.equal res.body.navn, '46793be9a59a0582d6c12376b4abb145'
      assert.deepEqual res.body.privat, secret: '4b65e2c69472621d4b33dd0e0bd66205'
      done()

  it 'should return document when status=Offentlig and tilbyder=DNT for not DNT', (done) ->
    req.get(url('52407fb375049e5615000469', true)).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.navn, 'c818b09c3c51eb6f6f4ddc4c87a2a4f3'
      assert.equal typeof res.body.privat, 'undefined'
      done()

  it 'should not return document when status=Kladd and tilbyder=DNT for not DNT', (done) ->
    req.get(url('52d65048dfb20d629566667c', true)).expect(404, done)

  it 'should not return document when status=Privat and tilbyder=DNT for not DNT', (done) ->
    req.get(url('52d65b2544db971c94b2d949', true)).expect(404, done)

  it 'should set X-Cache-Hit header for cache hit', (done) ->
    req.get(url('52407fb375049e5615000296')).expect(200).end (err, res) ->
      assert.ifError(err)
      req.get(url('52407fb375049e5615000296')).expect(200).expect('X-Cache-Hit', 'true', done)

  it 'should set last modified header correctly', (done) ->
    req.get(url('52407fb375049e561500038d'))
      .expect(200)
      .expect('Last-Modified', 'Mon, 16 Dec 2013 14:20:19 GMT', done)

  it 'should set Etag header correctly', (done) ->
    req.get(url('52407fb375049e5615000304')).expect(200).end (err, res) ->
        assert.ifError(err)
        assert.equal res.header.etag, 'd23c2905203cbbf4ad3cdb9367da5983'
        done()

  # Etag / checksum
  it 'should return 403 when provided with currently valid Etag', (done) ->
    req.get(url('52407fb375049e56150001bf'))
      .set('if-none-match', 'ddbe37ead8031e1fe21fc7d51b3920cd')
      .expect(304, done)

  it 'should return document for invalid Etag', (done) ->
    req.get(url('52407fb375049e56150001bf'))
      .set('if-none-match', '1606472306e24cdaf66d11ae808176cb')
      .expect(200).end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.navn, 'd119ff9ec3e34ae5194717b4f228c8bb'
        done()

  it 'should return documents without checksum', (done) ->
    req.get(url('52d65048dfb20d629566667c')).expect(200).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.navn, '30f832f2a56d8ccf2e6356e0556d545f'
      assert.equal typeof res.body.checksum, 'undefined'
      done()

  it 'should ignore etags for documents without checksum', (done) ->
    req.get(url('52d65048dfb20d629566667c')).set('if-none-match', 'ffa286997064c42f53861d4c945e2815')
      .expect(200).end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.navn, '30f832f2a56d8ccf2e6356e0556d545f'
        assert.equal typeof res.body.checksum, 'undefined'
        done()

  # Modified / endret
  it 'should return 403 when provided with equal modified since date', (done) ->
    req.get(url('52407fb375049e56150001bf'))
      .set('if-modified-since', '2013-12-16T14:25:47.966Z')
      .expect(304, done)

  it 'should return 403 when provided with newer modified since date', (done) ->
    req.get(url('52407fb375049e56150001bf'))
      .set('if-modified-since', '2014-12-16T14:25:47.966Z')
      .expect(304, done)

  it 'should return document for outdated modified since date', (done) ->
    req.get(url('52407fb375049e56150001bf'))
      .set('if-modified-since', '2012-12-16T14:25:47.966Z')
      .expect(200).end (err, res) ->
        assert.ifError(err)
        assert.equal res.body.navn, 'd119ff9ec3e34ae5194717b4f228c8bb'
        done()

  it 'should return newly created document', (done) ->
    doc = JSON.parse(JSON.stringify(steder[51]))
    delete doc._id
    delete doc.tilbyder
    delete doc.endret
    delete doc.checksum

    req.post('/steder/?api_key=dnt').send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      req.get(url(res.body.document._id)).expect(200).end (err, res) ->
        assert.ifError(err)
        assert.deepEqual res.body[key], val for val, key in doc
        done()

  it 'should return newly created document (with id)', (done) ->
    doc = JSON.parse(JSON.stringify(steder[51]))
    doc._id = new ObjectID()
    delete doc.tilbyder
    delete doc.endret
    delete doc.checksum

    req.post('/steder/?api_key=dnt').send(doc).expect(201).end (err, res) ->
      assert.ifError(err)
      assert.equal res.body.document._id, doc._id
      req.get(url(doc._id)).expect(200).end (err, res) ->
        assert.ifError(err)
        assert.deepEqual res.body[key], val for val, key in doc
        done()

  it 'should handle rapid fire', (done) ->
    this.timeout(5000)

    limit = 100
    for i in [0..limit]
      req.get(url(steder[i]._id)).expect(200).end (err, res) ->
        assert.ifError(err)
        done() if --limit is 0

describe 'HEAD', ->
  it 'should only get http header for document resource', (done) ->
    req.head(url('52407fb375049e561500047c')).expect(200)
      .expect('X-Cache-Hit', 'false')
      .expect('ETag', 'bfcec6b8b527a8d599ecfcbbea54a7f3')
      .expect('Last-Modified', 'Mon, 16 Dec 2013 14:34:51 GMT')
      .end (err, res) ->
        assert.ifError(err)
        assert.deepEqual(res.body, {})
        done()

describe 'POST', ->
  it 'should not be an allowed method', (done) ->
    req.post(url('52407fb375049e561500008f')).expect 405, done

describe 'PUT', ->
  it 'should return error for missing request body', (done) ->
    req.put(url('52407fb375049e5615000218')).expect(400, done)

  it 'should return error if request body is an array', (done) ->
    req.put(url('52407fb375049e5615000218')).send(['foo']).expect(400, done)

  it 'should update single object in collection', (done) ->
    u = url('52407fb375049e56150001fd')
    req.get(u).expect(200).end (err, res) ->
      doc = res.body
      doc.navn = 'Breidablik'
      req.put(u).send(doc).expect(200).end (err, res) ->
        req.get(u).expect(200).end (err, res) ->
          ignore = ['tilbyder', 'endret', 'checksum']
          assert.deepEqual val, doc[key] for val, key in res.body when key not in ignore
          done()

  it 'should override tilbyder, endret and checksum fields', (done) ->
    u = url('52407fb375049e561500008c')
    req.get(u).expect(200).end (err, res) ->
      doc = res.body
      doc.tilbyder = 'MINAPP'
      doc.endret   = new Date().toISOString()
      doc.checksum = '332dcf1830ec8e2c9bdc574b29515047'
      doc.navn     = 'Fonnabu'
      req.put(u).send(doc).expect(200).end (err, res) ->
        req.get(u).expect(200).end (err, res) ->
          ignore = ['tilbyder', 'endret', 'checksum']
          assert.notEqual val, doc[key] for val, key in res.body when key in ignore
          assert.deepEqual val, doc[key] for val, key in res.body when key not in ignore
          done()

  it 'should prevent unauthorized edits', (done) ->
    u = url('52407fb375049e5615000034', true)
    req.get(u).expect(200).end (err, res) ->
      doc = res.body
      doc.navn = 'Holmaskjer'
      req.put(u).send(doc).expect(403).end (err, res) ->
        assert.ifError(err)
        req.get(u).expect(200).end (err, res) ->
          assert.ifError(err)
          assert.notEqual res.body.navn, doc.navn
          done()

  # @TODO(starefossen) this test can be better
  it 'should cache document changes', (done) ->
    u = url('52407fb375049e56150002b3')
    req.get(u).expect(200).expect('x-cache-hit', 'false').end (err, res) ->
      doc = res.body
      doc.navn = 'Solrenningen'
      req.put(u).send(doc).expect(200).end (err, res) ->
        req.get(u).expect(200).expect('x-cache-hit', 'true', done)

  it 'should warn about missing lisens and status fields', (done) ->
    u = url('52407fb375049e561500047c')
    req.get(u).expect(200).end (err, res) ->
      doc = res.body
      delete doc.lisens
      delete doc.status
      req.put(u).send(doc).expect(200).end (err, res) ->
        assert.deepEqual res.body.warnings, [{
          resource: 'steder'
          field: 'lisens'
          value: 'CC BY-ND-NC 3.0 NO'
          code: 'missing_field'
        }, {
          resource: 'steder'
          field: 'status'
          value: 'Kladd'
          code: 'missing_field'
        }]
        done()

describe 'PATCH', ->
  it 'should not be implmented', (done) ->
    req.patch(url('52407fb375049e561500008f')).expect 501, done

describe 'DELETE', ->
  it 'should not be implmented', (done) ->
    req.del(url('52407fb375049e561500008f')).expect 501, done


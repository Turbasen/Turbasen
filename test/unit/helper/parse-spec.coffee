assert = require 'assert'
ObjectID  = require('mongodb').ObjectID

parse = require '../../../coffee/helper/parse'

describe 'docDefaults()', ->
  it 'should set endret to current data', ->
    [warn, data] = parse.docDefaults 'steder', {endret: '2014-07-04T08:51:46.355Z'}, false
    assert.equal typeof data.endret, 'string'
    assert data.endret > '2014-07-04T08:51:46.355Z'
    assert data.endret <= new Date().toISOString()

  it 'should set checksum to new random checksum', ->
    [warn, data] = parse.docDefaults 'steder', {checksum: 'abc123'}, false
    assert.equal typeof data.checksum, 'string'
    assert.notEqual data.checksum, 'abc123'
    assert /[a-f0-9]{32}/.test data.checksum

  it 'should warn and set if lisens is not specified', ->
    [warn, data] = parse.docDefaults 'steder', {status: 'Foo', navngiving: 'Bar'}, false
    assert.deepEqual warn, [resource: 'Document', field: 'lisens', code: 'missing_field']
    assert.equal data.lisens, 'CC BY 4.0'

  it 'should warn if navngiving is not specified', ->
    [warn, data] = parse.docDefaults 'steder', {status: 'Foo', lisens: 'Bar'}, false
    assert.deepEqual warn, [resource: 'Document', field: 'navngiving', code: 'missing_field']
    assert.equal data.navngiving, undefined

  it 'should warn and set if status if not specified', ->
    [warn, data] = parse.docDefaults 'steder', {lisens: 'Foo', navngiving: 'Bar'}, false
    assert.deepEqual warn, [resource: 'Document', field: 'status', code: 'missing_field']
    assert.equal data.status, 'Kladd'

  it 'should not check missing fields if isPatch flag is set', ->
    [warn, data] = parse.docDefaults 'steder', {}, true
    assert.deepEqual warn, []

describe 'docValidate()', ->
  it 'should validate required schema', (done) ->
    parse.docValidate 'steder', geojson: type: 123, (err) ->
      assert /type must be a string/.test err
      done()

  it 'should validate optional schema', (done) ->
    parse.docValidate 'steder', navn: 123, (err) ->
      assert /navn must be a string/.test err
      done()

  # @TODO(starefossen) this could be done better
  it 'should validate type specific schemas', (done) ->
    types =
      bilder:
        expect: /type must be one of Point. coordinates is required/
      grupper:
        expect: /type must be one of Polygon. coordinates is required/
      turer:
        expect: /type must be one of LineString. coordinates is required/
      områder:
        expect: /type must be one of Polygon. coordinates is required/
      steder:
        expect: /type must be one of Point. coordinates is required/
    i = Object.keys(types).length

    for type, val of types
      parse.docValidate type, {geojson: type: 'Foo'}, (err) ->
        assert val.expect.test(err), "#{type} assertion failed"
        done() if --i is 0

describe 'docInsert()', ->
  it 'should set _id if not provided', (done) ->
    parse.docInsert 'steder', {}, (err, warn, data) ->
      assert.ifError err
      assert.notEqual data._id, undefined
      done()

  it 'should return _id as ObjectID', (done) ->
    parse.docInsert 'steder', _id: '53b673aef3a92bc52a80414b', (err, warn, data) ->
      assert.ifError err
      assert data._id instanceof ObjectID, '_id is not instance of ObjectID'
      done()

  it 'should preserve _id if provided', (done) ->
    parse.docInsert 'steder', _id: '53b673aef3a92bc52a80414b', (err, warn, data) ->
      assert.ifError err
      assert.equal data._id.toString(), '53b673aef3a92bc52a80414b'
      done()

  it 'should warn about missing fields', (done) ->
    parse.docInsert 'steder', {}, (err, warn, data) ->
      assert.ifError err
      assert.notEqual warn.length, 0
      done()

  it 'should return error for schema errors', (done) ->
    parse.docInsert 'steder', navn: 123, (err, warn, data) ->
      assert err instanceof Error, 'error is not instance of Error'
      done()

describe 'docReplace()', ->
  it 'should remove _id', (done) ->
    parse.docReplace 'steder', _id: '53b673aef3a92bc52a80414b', (err, warn, data) ->
      assert.ifError err
      assert.equal data._id, undefined
      done()

  it 'should warn about missing fields', (done) ->
    parse.docReplace 'steder', {}, (err, warn, data) ->
      assert.ifError err
      assert.notEqual warn.length, 0
      done()

  it 'should return error for schema errors', (done) ->
    parse.docReplace 'steder', navn: 123, (err, warn, data) ->
      assert err instanceof Error, 'error is not instance of Error'
      done()

describe 'docPath()', ->
  it 'should move orphane root fields to $set', (done) ->
    parse.docPatch 'steder', navn: 'abc', (err, warn, data) ->
      assert.ifError err
      assert.equal data.navn, undefined
      assert.equal data.$set.navn, 'abc'
      done()

  it 'should $set default keys', (done) ->
    parse.docPatch 'steder', {}, (err, warn, data) ->
      assert.ifError err
      assert.notEqual Object.keys(data.$set).length, 0
      done()

  it 'should preserve $set keys', (done) ->
    parse.docPatch 'steder', $set: foo: 'bar', bar: 'foo', (err, warn, data) ->
      assert.ifError err
      assert.equal data.$set.foo, 'bar'
      assert.equal data.$set.bar, 'foo'
      done()

  it 'should preserve $unset, $push, and $pull keys', (done) ->
    i = 3
    for verb in ['$unset', '$push', '$pull']
      orig = {}
      orig[verb] = foo: 'bar', bar: 'foo'
      parse.docPatch 'steder', orig, (err, warn, data) ->
        assert.ifError err
        assert.deepEqual data[verb], foo: 'bar', bar: 'foo', "#{verb} failed"
        done() if --i is 0

  it 'should prevent $set to read only fields', (done) ->
    orig = $set: _id: '', tilbyder: '', endret: '', checksum: '', navn: 'abc'
    parse.docPatch 'steder', orig, (err, warn, data) ->
      assert.ifError err
      assert.equal data.$set._id, undefined
      assert.equal data.$set.tilbyder, undefined
      assert.notEqual data.$set.endret, ''
      assert.notEqual data.$set.checksum, ''
      assert.equal data.$set.navn, 'abc'
      done()

  it 'should prevent $unset, $push, and $pull to required fields', (done) ->
    i = 3
    for verb in ['$unset', '$push', '$pull']
      orig = {}
      orig[verb] =
        _id: '', tilbyder: '', endret: '', checksum: ''
        lisens: '', navngiving: '', status: '', navn: 'abc'
      parse.docPatch 'steder', orig, (err, warn, data) ->
        assert.ifError err
        assert.deepEqual data[verb], {navn: 'abc'}, "#{verb} failed"
        done() if --i is 0

  it 'should not warn about missing fields', (done) ->
    parse.docPatch 'steder', {}, (err, warn, data) ->
      assert.ifError err
      assert.deepEqual warn, []
      done()

  it 'should return error for $set schema errors', (done) ->
    parse.docPatch 'steder', navn: 123, (err, warn, data) ->
      assert err instanceof Error, 'error is not instance of Error'
      done()


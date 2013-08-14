assert = require 'assert'
database = require './../coffee/database'

describe '#connect()', ->
  beforeEach ->
    delete process.env['MONGO_NODE_DRIVER_PORT']
    delete process.env['MONGO_NODE_DRIVER_HOST']

  it 'should return an error if database port is closed', (done) ->
    process.env['MONGO_NODE_DRIVER_PORT'] = 12345
    database.connect 'foo', (err, db) ->
      assert.notEqual err, null, 'err should not be null'
      assert err instanceof Error, 'err should be Error'
      assert.equal db, null
      done()

  it.skip 'should return error if database does not exist', (done) ->
    database.connect 'foo', (err, db) ->
      #console.log db
      #assert.fail()
      done()

  it 'should connect to default database if none provided', (done) ->
    database.connect null, (err, db) ->
      assert.equal err, null, 'err should be null'
      assert.notEqual db, null, 'db should not be null'
      assert.equal db.databaseName, 'ntb_07', 'database should be ntb_07'
      done()

  it 'should not suprepress runtime errors', (done) ->
    database.connect null, (err, db) ->
      try
        foobar()
      catch e
        assert e instanceof Error, 'e should be an instance of error'
        assert /ReferenceError: foobar is not defined/.test(e), 'e should be ReferenceError'
        done()


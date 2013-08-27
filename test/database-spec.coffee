assert = require 'assert'
database = require './../coffee/database'

describe '#connect()', ->
  MONGO_DEV_URI = process.env['MONGO_DEV_URI']
  MONGO_STAGE_URI = process.env['MONGO_STAGE_URI']
  MONGO_PROD_URI = process.env['MONGO_PROD_URI']
  MODE = process.env['MODE']

  afterEach ->
    process.env['MONGO_DEV_URI'] = MONGO_DEV_URI
    process.env['MONGO_STAGE_URI'] = MONGO_STAGE_URI
    process.env['MONGO_PROD_URI'] = MONGO_PROD_URI
    process.env['MODE'] = MODE

  it 'should return an error if database connections fails', (done) ->
    process.env['MONGO_DEV_URI'] = 'mongodb://undefined:1234/foo'
    database.connect null, (err, db) ->
      assert.notEqual err, null, 'err should not be null'
      assert err instanceof Error, 'err should be Error'
      assert.equal db, null
      done()

  it.skip 'should return error if database does not exist', (done) ->
    database.connect null, (err, db) ->
      #console.log db
      #assert.fail()
      db.close ->
        done()

  it 'should connect to curstom database uri if specified', (done) ->
    process.env['MONGO_DEV_URI'] = 'mongodb://localhost:27017/ntb_test'
    database.connect null, (err, db) ->
      assert.equal err, null, 'err should be null'
      assert.notEqual db, null, 'db should not be null'
      assert.equal db.databaseName, 'ntb_test', 'database should be ntb_test'
      db.close ->
        done()

  it 'should not suprepress runtime errors', (done) ->
    database.connect null, (err, db) ->
      try
        foobar()
      catch e
        assert e instanceof Error, 'e should be an instance of error'
        assert /ReferenceError: foobar is not defined/.test(e), 'e should be ReferenceError'
        db.close ->
          done()

describe '#each()', ->
  db = col = null

  before (done) ->
    database.connect null, (err, database) ->
      throw err if err
      db = database
      db.collection 'turer', (err, collection) ->
        throw err if err
        col = collection
        done()

  after (done) -> db.close -> done()

  it 'should itterate over database cursor', (done) ->
    @timeout 10000

    cursor = col.find()
    counter = 0

    database.each cursor, (doc, i, count, cb) ->
      counter++
      cb()
    , (err, i, count) ->
      throw err if err
      assert.equal counter, count
      assert.equal i+1, count
      done()

  it 'should ittereate over database cursor with limit', (done) ->
    cursor  = col.find().limit(10)
    counter = 0

    database.each cursor, (doc, i, count, cb) ->
      counter++
      cb()
    , (err, i, count) ->
      throw err if err
      assert.equal counter, 10
      assert.equal i, 9
      assert.equal count, 10
      done()


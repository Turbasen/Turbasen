assert = require 'assert'
turbase = require './../coffee/turbase'

describe '#getTypes()', ->
  it 'should get all avaiable data types', (done) ->
    turbase.getTypes {},
      jsonp: (data) ->
        assert data.types instanceof Array, 'types should be an Array'
        assert.equal typeof data.count, 'number', 'count should be a number'
        assert.equal data.count, data.types.length, 'count should equal data.types.length'
        assert 'aktiviteter' in data.types, 'types should contain aktiviteter'
        assert 'bilder' in data.types, 'types should contain bilder'
        assert 'områder' in data.types, 'types should contain områder'
        assert 'steder' in data.types, 'types should contain steder'
        assert 'turer' in data.types, 'types should contain turer'
        done()

describe.skip '#get()', ->
  it 'should get without errors', (done) ->
    req =
      params:
        object: 'turer'
        id: 'abc'
    #turbase.get
    done()

describe.skip '#list()', ->
  it 'should list all the tings'

describe.skip '#insert()', ->
  it 'should insert all the things'

describe.skip '#update()', ->
  it 'should update all the things'

describe.skip '#updates()', ->
  it 'should updates all the things'

describe.skip '#delete()', ->
  it 'should delete all the things'


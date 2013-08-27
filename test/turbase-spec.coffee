turbase = require './../coffee/turbase'

describe '#get()', ->
  it 'should get without errors', (done) ->
    req =
      params:
        object: 'turer'
        id: 'abc'
    #turbase.get
    done()

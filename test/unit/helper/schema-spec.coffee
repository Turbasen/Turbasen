assert  = require 'assert'
joi     = require 'joi'
schema  = require '../../../coffee/helper/schema'

data =
  grupper : require '../../data/gruppe.json'
  bilder  : require '../../data/bilde.json'
  turer   : require '../../data/tur.json'
  områder : require '../../data/omrade.json'
  steder  : require '../../data/sted.json'

validate = (schemaType, dataType) ->
  s = schema[schemaType]
  s = s[dataType] if schemaType is 'type'

  j = joi.validate data[dataType], s, allowUnknown: true

  assert.strictEqual null, j.error

describe 'required', ->
  for dataType of data
    do (dataType) ->
      it "should validate test #{dataType}", ->
        validate 'required', dataType

describe 'optional', ->
  it 'should allow ampty tag array', ->
    j = joi.validate tags: [], schema.optional, allowUnknown: true

    assert.strictEqual j.error, null

  for dataType of data
    do (dataType) ->
      it "should validate test #{dataType}", ->
        validate 'optional', dataType

describe 'type specific', ->
  for dataType of data
    do (dataType) ->
      it "should validate test #{dataType}", ->
        validate 'type', dataType


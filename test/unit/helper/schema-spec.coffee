assert  = require 'assert'
joi     = require 'joi'
schema  = require '../../../coffee/helper/schema'

data =
  grupper : require '../../data/gruppe.json'
  bilder  : require '../../data/bilde.json'
  turer   : require '../../data/tur.json'
  områder : require '../../data/område.json'
  steder  : require '../../data/sted.json'

validate = (schemaType, dataType) ->
  s = schema[schemaType]
  s = s[dataType] if schemaType is 'type'

  j = joi.validate data[dataType], s, allowUnknown: true

  assert.strictEqual null, j.error

for schemaType in ['required', 'optional', 'type']
  do (schemaType) ->
    describe "#{schemaType}", ->
      for dataType of data
        do (dataType) ->
          it "should validate #{dataType}", ->
            validate schemaType, dataType


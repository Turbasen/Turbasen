'use stict'

ObjectID = require('mongodb').ObjectID

doc =
  _id: new ObjectID '52d67a93b9fab76c0894c650'
  tilbyder: 'DNT'
  endret: '2014-01-15T12:08:07.070Z'
  checksum: '5f6f0608b95ad250b5cdc4d23209f19e'
  status: 'Offentlig'
  navn: 'Test Data'
  privat: secret: 'c17aa86d45ae1fae5bccc9894b364d06'
  bilder: ['52d67a93b9fab76c0894c651', '52d67a93b9fab76c0894c652']
  grupper: ['52d67a93b9fab76c0894c653']

exports.getDoc = (oid) ->
  return JSON.parse(JSON.stringify(doc)) if typeof oid is 'undefined'
  return doc

exports.redisify = (data) ->
  obj = {}
  for key in Object.keys data
    val = data[key]
    val = val.join(',') if val instanceof Array
    obj[key] = val
  return obj

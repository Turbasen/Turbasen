assert = require 'assert'

cache = require '../../../coffee/helper/cache'
steder = null

before -> steder = module.parent.exports.steder

describe 'getFilter()', ->
  it 'should return cache filter for type', ->
    assert.deepEqual cache.getFilter('steder'),
      _id       : false
      tilbyder  : true
      endret    : true
      checksum  : true
      status    : true
      lisens    : true
      navn      : true
      områder   : true
      steder    : true
      bilder    : true
      grupper   : true

describe 'filterData()', ->
  it 'should return filtered data for type', ->
    assert.deepEqual cache.filterData('steder', steder[32]),
      tilbyder: 'DNT'
      endret: '2013-12-16T14:19:26.938Z'
      checksum: 'e6bfd76b7fa1b9fc3dfac9f5d5e083e9'
      status: 'Offentlig'
      lisens: 'CC BY 4.0'
      navn: 'be35d2bbf9b4077bbd38ad5454e590b1'
      områder: [
        '52408144e7926dcf1500000e'
        '52408144e7926dcf1500004b'
      ]
      bilder: [
        '5242a063f92e7d7112000cd3'
        '5280e964ce839a210200042a'
        '5242a068f92e7d711203290d'
      ]
      grupper: ['52407f3c4ec4a1381500025d']

describe 'arrayify()', ->
  it 'should return arrays for type fields', ->
    data =
      områder: 'foo,bar'
      grupper: 'baz'
      bilder: 'biz,boz,bex'

    assert.deepEqual cache.arrayify('steder', data),
      områder: ['foo', 'bar']
      grupper: ['baz']
      bilder: ['biz', 'boz', 'bex']
      steder: []


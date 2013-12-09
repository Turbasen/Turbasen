"use strict"

generator = new (require('./fakeData').Generator)()

data =
  turer: generator.gen 100, type: 'turer', oid: true
  steder: generator.gen 100, type: 'steder', oid: true

turer = {}
for doc,key in data.turer
  turer[doc.tilbyder] = {} if not turer[doc.tilbyder]
  turer[doc.tilbyder][doc.status] = key

rand = (max, min) -> Math.floor (Math.random() * (max - min + 1) + min)

exports.getTypes = -> Object.keys(data)
exports.getTrip = (vendor, status) -> data.turer[turer[vendor or 'DNT'][status or 'Offentlig']]
exports.new = (type, i) -> generator.gen (i or 0), type: type
exports.get = (type, all, n) ->
  return data[type] if all
  return JSON.parse(JSON.stringify(data[type][n])) if n
  return JSON.parse(JSON.stringify(data[type][rand(0, data[type].length-1)]))


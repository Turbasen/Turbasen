"use strict"

ObjectID = require('mongodb').ObjectID
Moniker = require('moniker')

rand = (min, max) -> Math.floor (Math.random() * (max - min + 1) + min)

lisence = [
  "CC BY-NC-ND 3.0 NO"
  "CC BY-NC 3.0 NO"
  "CC BY-ND 3.0 NO"
  "CC BY 3.0 NO"
]

provider = [
  "DNT"
  "NRK"
  "TURAPP"
]

statuses = [
  "Offentlig"
  "Privat"
  "Kladd"
  "Slettet"
]

tags = [
  'Sted'
  'Hytte'
]

module.exports = (num) ->
  now = new Date().getTime()
  past = now - 100000000000
  num = num or 100
  ret = []

  for i in [1..num]
    d1 = rand(past, now)
    d2 = rand(d1, now)

    ret.push
      _id: new ObjectID()
      opprettet: new Date(d1).toISOString()
      endret: new Date(d2).toISOString()
      tilbyder: provider[rand(0, provider.length-1)]
      lisens: lisence[rand(0, lisence.length-1)]
      status: statuses[rand(0, statuses.length-1)]
      navn: Moniker.choose()
      tags: [tags[rand(0, tags.length-1)]]
      privat:
        foo: Moniker.choose()
        bar: Moniker.choose()

  ret


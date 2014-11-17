"use strict"

rand = (min, max) -> Math.floor(Math.random() * (max - min + 1)) + min

MongoClient = require('mongodb').MongoClient
MongoClient.connect "mongodb://localhost:27017/test", (err, db) ->
  throw err if err

  console.log 'Database is connected...'

  users = [
    {
      id: 1234
      navn: 'Ola Nordmann'
    }
    {
      id: 'https://openid.provider.com/user/abcd123'
      navn: 'Kari Nordmann'
      epost: 'kari@nordmann.no'
    }
    {
      id: 3456
      navn: 'Per Olsen'
      epost: 'per.olsen@gmail.com'
    }
    {
      id: 6789
      navn: 'Kristin Pettersen'
    }
  ]

  count = 0
  db.collection('steder').find().each (err, doc) ->
    if doc is null
      db.close() if count is 0
      return

    user = users[rand(0,users.length+2)]

    return if not user

    if user
      count++
      console.log doc._id, 'updating...'
      update =
        '$set':
          privat:
            secret: doc.privat.secret
            opprettet_av: user
      db.collection('steder').update {_id: doc._id}, update, (err) ->
        throw err if err
        console.log doc._id, 'updated!'
        db.close() if --count is 0


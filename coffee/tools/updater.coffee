#
# NTB MongoDB updater script
#
# @author Hans Kristian Flaatten
#

"use strict"

mongodb = require 'mongodb'
database = require './../database.coffee'

database.connect 'ntb_07', (err, db) ->
  return console.log err if err

  console.log 'Database connection is open'

  db.collection 'aktiviteter', (err, collection) ->
    return console.log err if err
    
    console.log "Collection is open"

    collection.count (err, count) ->
      console.log 'collection.count', count
    
    cursor = collection.find().limit(4)

    database.each cursor, (doc, i, count, cb) ->
      console.log doc
      cb()
      #doc.url = 'http://' + doc.url
      #collection.save doc, (err, doc) ->
      #  console.log err if err
      #  cb err
    , (err, i, count) ->
      console.log err, i, count
      db.close ->
        console.log 'db is closed!'



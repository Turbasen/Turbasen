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

  db.collection 'bilder', (err, collection) ->
    return console.log err if err
    
    console.log "Collection is open"

    cursor = collection.find().limit(2)
    #$where : "this.geojson && this.geojson.coordinates[0] > 50"
    
    database.each cursor, (doc, cb) ->
      console.log doc
      cb()
    , (err, i) ->
      console.log 'cursor end', i
      db.close()


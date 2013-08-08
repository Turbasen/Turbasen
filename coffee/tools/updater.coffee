#
# NTB MongoDB updater script
#
# @author Hans Kristian Flaatten
#

"use strict"

mongodb = require 'mongodb'
database = require './../database'

database.connect 'ntb_07', (err, db) ->
  return console.log 'db err', err if err
  
  console.log 'Database connection is open'

  db.collection 'aktiviteter', (err, collection) ->
    if err
      console.log 'db connection failed'
      console.log err
      return db.close()
    
    console.log "Collection is open"
  
    update = (doc, cb) ->
      return cb null if doc.geojson.coordinates[0] < doc.geojson.coordinates[1]
      
      coords = doc.geojson.coordinates

      lat = coords[0]
      lng = coords[1]

      coords[0] = lng
      coords[1] = lat

      if typeof coords[2] is 'undefined' or coords[2] is 0
        coords[2] = -999

      doc.geojson.coordinates = coords
      console.log doc.geojson.coordinates

      collection.save doc, (err) ->
        cb err

    collection.find {"geojson" : {$exists: true}}, (err, cursor) ->
      if err
        console.log 'collection.find() failed'
        console.log err
        return db.close()

      database.each cursor, update, (err) ->
        if err
          console.log 'database update failed'
          console.log err
        else
          console.log 'databse update success'

        db.close()


        

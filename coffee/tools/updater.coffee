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


  db.on 'error', (error, db) ->
    console.log 'db.error', error
    db.close()
  
  console.log 'Database connection is open'

  db.collection 'turer', (err, collection) ->
    if err
      console.log 'db connection failed'
      console.log err
      return db.close()
    
    console.log "Collection is open"

    update = (doc, cb) ->
      #if doc.privat.lenker
      #  for link in doc.privat.lenker
      #    if not link.url.match(/^http(s?):\/\//m)
      #      console.log link.url
      #      #return cb new Error('end')
      #
      #if doc.privat.eier
      #  for eier in doc.privat.eier
      #    if eier.url and not eier.url.match(/^http(s?):\/\//m)
      #      console.log eier.url
      
      cb()

    collection.find {"privat" : {$exists: true}}, (err, cursor) ->
      console.log 'collection.find run'

      if err
        console.log 'collection.find() failed'
        console.log err
        return db.close()

      database.each cursor, update, (err, count) ->
        console.log 'count', count

        if err
          console.log 'database update failed'
          console.log err
        else
          console.log 'databse update success'

        db.close()


        

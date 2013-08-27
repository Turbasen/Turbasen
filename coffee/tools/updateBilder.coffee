#
# Document update
#
# @database ntb_07
# @collection bilder
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

    collection.count (err, count) ->
      console.log 'collection.count', count
    
    #database.each collection.find().limit(200), (img, i, count, cb) ->
    database.each collection.find(), (img, i, count, cb) ->
      console.log i if i%100 is 0
      parseTags = (j, tags, cb) ->
        #console.log j, tags, tags.length
        return cb(null, tags) if not tags or j is tags.length

        tag = tags[j].split ':'
        map = {trip:'turer', cabin:'steder'}

        if tag.length isnt 2 or typeof map[tag[0]] is 'undefined'
          return parseTags ++j, tags, cb
          
        db.collection map[tag[0]], (err, col) ->
          return praseTags ++j, tags, cb if err
          database.each col.find({"privat.id":parseInt(tag[1])}), (doc, k, count, cb) ->
            tags[j] = "#{tag[0]}:#{doc._id}" if doc isnt null
            cb()
          , (err, k, count) ->
            parseTags ++j, tags, cb
 
      parseTags 0, img.tags.slice(), (err, tags) ->
        if err
          console.log err if err
          return cb()

        img.tags = tags

        collection.save img, (err, doc) ->
          console.log err if err
          cb()

    , (err, i, count) ->
      console.log err, i, count
      db.close()



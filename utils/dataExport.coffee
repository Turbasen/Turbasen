"use strict"

fs = require 'fs'
MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID

createHash = require('crypto').createHash

uri = "mongodb://api-prod:794a41842dd9d73d551e1fdf804d980e@zoe.mongohq.com:10096/nasjonalturbase"
export_dir  = './test/data/'

MongoClient.connect uri, (err, db) ->
  throw err if err

  console.log 'database connected...'

  exportQuery = (coll, query, proj, cb) ->
    i = 0

    groups = []
    areas  = []
    images = []

    file = export_dir + coll + '.json'

    console.log coll + ' export started...'

    fs.writeFileSync file, '['
    db.collection(coll).find(query, proj).each (err, doc) ->
      if doc is null
        console.log coll + ' export finished!'
        return fs.appendFile file, ']', (err) ->
          throw err if err
          cb groups, areas, images

      doc.bilder = doc.bilder.slice 0, 3 if doc.bilder

      groups.push(g) for g in doc.grupper when g not in groups if doc.grupper
      areas.push(a)  for a in doc.områder when a not in areas  if doc.områder
      images.push(j) for j in doc.bilder  when j not in images if doc.bilder

      doc.img[key].url = createHash('md5').update(JSON.stringify(val.url)).digest('hex') for val, key in doc.img if doc.img

      d = {}
      d._id         = '$oid': doc._id # This is how "mongoexport --jsonArray" does it
      d.tilbyder    = 'TEST'
      d.endret      = doc.endret
      d.checksum    = ''
      d.lisens      = 'CC BY-NC 3.0 NO'
      d.navngiving  = 'Test Data'
      d.status      = 'Offentlig'
      d.navn        = createHash('md5').update(doc.navn).digest('hex') if doc.navn
      d.geojson     = doc.geojson if doc.geojson and coll in ['steder', 'turer']
      d.områder     = doc.områder if doc.områder
      d.tags        = doc.tags if doc.tags
      d.grupper     = doc.grupper if doc.grupper
      d.privat      = secret: createHash('md5').update(doc.endret).digest('hex')
      d.bilder      = doc.bilder if doc.bilder
      d.img         = doc.img if doc.img
      d.checksum    = createHash('md5').update(JSON.stringify(doc)).digest('hex')

      console.log i if ++i % 10 is 0

      pre = if i > 1 then ',' else ''
      fs.appendFile file, pre + JSON.stringify(d), (err) ->
        throw err if err

  query = grupper: "$in": ["52407f3c4ec4a1381500025d", "52407f3c4ec4a13815000246"]
  proj  = endret: true, navn: true, geojson: true, områder: true, tags: true, grupper: true, bilder: true, img: true

  exportQuery 'steder', query, proj, (groups, areas, images) ->
    i = 3

    groups[key] = new ObjectID(val) for val,key in groups
    areas[key] = new ObjectID(val) for val,key in areas
    images[key] = new ObjectID(val) for val,key in images

    exit = -> db.close() if --i is 0

    #proj.geojson = false # dont include geojson for other stuff

    exportQuery 'grupper', {_id: "$in": groups}, proj, exit
    exportQuery 'områder', {_id: "$in": areas}, proj, exit
    exportQuery 'bilder', {_id: '$in': images}, proj, exit


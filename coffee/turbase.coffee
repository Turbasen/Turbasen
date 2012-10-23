#
# Nasjonal Turbase 
#

mongodb = require 'mongodb'
#MongoDB kobling
server  = new mongodb.Server "127.0.0.1", 27017, {safe:true, auto_reconnect: true}, {}
db      = new mongodb.Db 'dnt', server, {}
db.open(()->)

exports.get = (req, res) ->
  db.collection req.params.object, (err, collection) ->
    res.jsonp "{'error':#{err}}" if err
    collection.find({_id: mongodb.ObjectID(req.params.id)}).toArray (err, result) ->
      res.jsonp result if result
      res.jsonp err if err

exports.list = (req, res) ->
  limit   = req.query.limit or 10
  offset  = req.query.offset or 0
  console.log req.eier
  # sett inn dynamisk collection her: req.params.object
  db.collection req.params.object, (err, collection) ->
    res.jsonp "{'error':#{err}}" if err
    collection.find({'eier':req.eier}).toArray (err, result) ->
      res.jsonp result if result
      res.jsonp err if err

exports.insert = (req, res) ->
  #dynamisk collection via req.params.object
  db.collection req.params.object, (err, collection) ->
    res.jsonp "{'error':#{err}}" if err
    collection.insert req.data, {safe: true}, (err, records) ->
      res.jsonp err if err
      res.jsonp records

exports.update = (req, res) ->
  db.collection req.params.object, (err, collection) ->
    collection.update {'_id':mongodb.ObjectID(req.params.id), 'eier': req.eier}, {$set: req.data}, {safe: true}, (err, records) ->
      if not err
        collection.find({'_id':mongodb.ObjectID(req.params.id), 'eier': req.eier}).toArray (err, result) ->
          res.jsonp result if result
          res.jsonp err if err

exports.updates = (req, res) ->
  res.jsonp "Updates #{req.params.object} with data: #{req.query.data}"

exports.delete = (req, res) ->
  console.log "Delete"
  # Legg til eier-felt ved spesifisering av hva som skal slettes, slik at kun eier kan slette.
  # Eier-id bør ikke være api-key, da denne bør kunne byttes.
  db.collection req.params.object, (err, collection) ->
    console.log req.eier
    collection.remove {'_id':mongodb.ObjectID(req.params.id), 'eier': req.eier}, {safe: true}, (err, status) ->
      res.json '1' if not err
      res.json err if err

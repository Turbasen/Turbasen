#
# Nasjonal Turbase 
#

mongodb = require 'mongodb'
#MongoDB kobling
#server  = new mongodb.Server "127.0.0.1", 27017, {safe:true, auto_reconnect: true}, {}
#db      = new mongodb.Db 'ntb', server, {safe:true}
#db.open(()->)

replSet = new mongodb.ReplSet( [
  new mongodb.Server( '127.0.0.1', 27017, {}),
  new mongodb.Server( '127.0.0.1', 27018, {}),
  new mongodb.Server( '127.0.0.1', 27019, {})
  ]
)

db = new mongodb.Db('ntb_03', replSet, {native_parser: true})
console.log "Kobler seg til mongodb replica set ntb og database ntb_<versjon>"
db.open(()->)

exports.get = (req, res) ->
  db.collection req.params.object, (err, collection) ->
    res.jsonp "{'error':#{err}}" if err
    res.jsonp "{'error': 'Mangler id'}" if not req.params.id
    collection.find({_id: mongodb.ObjectID(req.params.id), 'eier':req.eier}).toArray (err, result) ->
      res.jsonp result if result
      res.jsonp err if err

exports.list = (req, res) ->
  limit   = parseInt(req.query.limit) or 10
  offset  = parseInt(req.query.offset) or 0
  # sett inn dynamisk collection her: req.params.object
  db.collection req.params.object, (err, collection) ->
    res.jsonp "{'error':#{err}}" if err
    collection.find({'eier':req.eier},{'tp_name':1}).limit(limit).skip(offset).toArray (err, result) ->
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
      else
        res.jsonp err

exports.updates = (req, res) ->
  res.jsonp "Updates #{req.params.object} with data: #{req.query.data}"

exports.delete = (req, res) ->
  # Legg til eier-felt ved spesifisering av hva som skal slettes, slik at kun eier kan slette.
  # Eier-id bør ikke være api-key, da denne bør kunne byttes.
  db.collection req.params.object, (err, collection) ->
    res.jsonp "{'error':#{err}}" if err
    collection.remove {'_id':mongodb.ObjectID(req.params.id), 'eier': req.eier}, {safe: true}, (err, status) ->
      res.jsonp "{'_id':#{req.params.id}, 'action':'delete', 'status':#{status}}" if not err
      res.jsonp JSON.stringify err if err

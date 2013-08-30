#
# Nasjonal Turbase 
#

mongodb = require 'mongodb'
ObjectID = mongodb.ObjectID
database = require './database'

db = null

database.connect null, (err, db_ref) ->
throw err if err
db = db_ref

exports.getTypes = (req, res) ->
res.jsonp
  types: ['aktiviteter', 'bilder', 'områder', 'steder', 'turer']
  count: 5

exports.get = (req, res) ->
db.collection req.params.object, (err, collection) ->
  # @TODO move to propper error handling
  return res.jsonp "{'error':#{err}}" if err
  return res.jsonp "{'error': 'Mangler id'}" if not req.params.id

  collection.findOne _id: ObjectID.createFromHexString(req.params.id), (err, doc) ->
    # @TODO move to propper error handling

    delete doc.privat if req.eier.toLowerCase() isnt doc?.eier?.toLowerCase()

    return res.jsonp err if err
    return res.jsonp doc if doc
    # @TODO this should 404 Not Found
    return res.jsonp {}

exports.list = (req, res) ->
# @TODO parse arguments in server.coffee
limit  = Math.min(parseInt(req?.query?.limit) || 10, 50)
offset = parseInt(req?.query?.offset) || 0
query  = {endret:{$gt:req.query.after}} if req?.query?.after

db.collection req.params.object, (err, collection) ->
  # @TODO move to propper error handling
  return res.jsonp "{'error':#{err}}" if err

  opts =
    limit: limit
    skip: offset
    sort: "endret"
    
  # @TODO add endret paramter
  # @TODO add support for queries
  collection.find(query,{eier:1,navn:1,endret:1},opts).toArray (err, result) ->
      # @TODO move to propper error handling
      return res.jsonp err if err
      return res.jsonp documents: result, count: result.length if result
      # @TODO what if neither?

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


# Nasjonal Turbase v1
#
# Server-Database connector
#
# This is a wrapper class between the requests to the server and the database.
# It is responsible for parsing and validating parameters, access controll,
# retrieving documents from from the database and handling errors.  
#
# @author Hans Kristian Flaatten
#

db = module.db

#
# Preprocess :object parameter
#
exports.paramObject = (req, res, next, object) ->
  db.getCollectionByType object, (err, collection) ->
    return next err if err
    return next new Error('ObjectTypeDoesntExist') if not collection

    req.collection = collection
    return next()

# 
# Preprocess :id parameter
#
exports.paramId = (req, res, next, id) ->
  # @TODO check hex24
  # req.objectId = db.parseObjectId(id)
  req.objectId = Object.createFromHexString(id)

#
# Get object types
#
# List collections in database. This is used for the elasticsearch-river-remote
# plugin when indexing.
#
# @TODO make this dynamic
#
exports.getObjectTypes = (req, res, next) ->
  res.jsonp
    types: ['aktiviteter', 'bilder', 'områder', 'steder', 'turer']
    count: 5

#
# Get objects
#
# Retrieve object for given object type
#
# req.db.collection, req.query.after
#
exports.getObjectsByType = (req, res, next) ->
  col     = req.db.collection
  query   = endret:{$gt:req.query.after} if req?.query?.after?
  fileds  = {}
  options =
    limit  : Math.min(parseInt(req?.query?.limit?) || 10, 50)
    offset : parseInt(req?.query?.offset?) || 0

  db.getDocumentsByCollection col, query, fields, options, (err, documents) ->
    return next err if err
    return res.jsonp
      documents: documents
      count: documents.length

#
# Get object
#
# Get object for given ObjectId
# 
# req.db.collection, req.db.objectId
#
exports.getObjectById = (req, res, next) ->
  col = req.db.collection
  id  = req.db.objectId

  db.getDocumentById col, id, (err, document) ->
    return next err if err
    return res.jsonp 404, {} if not document
    return res.jsonp document

#
# Insert object
#
exports.postObject = (req, res, next) ->


#
# Update object
#
exports.putObject = (req, res, next) ->

#
# Delete object
#
exports.deleteObject = (req, res, next) ->


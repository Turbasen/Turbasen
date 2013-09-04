# Nasjonal Turbase v1
#
# Server to Database handler
#
# This is a wrapper class between the requests to the server and the database.
# It is responsible for parsing and validating parameters, access controll,
# retrieving documents from from the database and handling errors.  
#
# @author Hans Kristian Flaatten
#

#
# Preprocess: ?api_key
#
# Verifies the provided API key anginst the datbase of registerd API keys. This
# method will perform throling and limiting exessive usage of the API.
#
# @error 403 - AuthenticationFailed
#
exports.apiKeyVerify = (req, res, next) ->
  keys =
    dnt: "DNT"
    nrk: "NRK"

  key = req?.get?('api_key') or req?.query?.api_key
  if not key or not keys[key]
    err = new Error('API Authentication Failed')
    err.mesg = 'AuthenticationFailed'
    err.code = 403
    return next err

  req.key =
    public: keys[key]

  # @TODO move this
  data = req.params?.data or req.query?.data
  if data
    req.data = JSON.parse data if data
    req.data.eier = req.eier

  next()

#
# Preprocess :object 
#
# Verifies the object parameter and connects to the appropriate collection. If
# connection fails this method will next an error {@code ObjectTypeNotExist}.
#
# @error MongoDB connection error
# @error ObjectTypeNotExist
#
exports.paramObject = (req, res, next, object) ->
  return next new Error('ObjectTypeNotExist') if /^(system|admin)/i.test object
  req.db.con.getCollection object, (err, collection) ->
    return next err if err
    return next new Error('ObjectTypeNotExist') if not collection

    req.db.col = collection
    return next()

# 
# Preprocess :id parameter
#
exports.paramId = (req, res, next, id) ->
  if /^[0-9a-f]{24}$/i.test id
    req.db.id = id
    next()
  else
    err = new Error('ID is not a string of 24 hex chars')
    err.code = 400
    err.mesg = 'ObjectIDMustBe24HexChars'
    next err

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
# Parse database query options
#
# @param req {@code object} - http request object
#
# @return {@code object} - opts.query, opts.limit, opts.skip
#
exports._parseOptions = (req) ->
  limit = 10
  limit = parseInt(req.query.limit) if req?.query?.limit

  skip = 0
  skip = parseInt(req.query.offset) if req?.query?.offset

  query = {}
  query.endret = {$gt:req.query.after} if req?.query?.after

  {
    query : query
    limit : Math.min(limit, 50)
    skip  : skip
  }

#
# Get objects
#
# Retrieve object for given object type
#
# req.db.collection, req.query.after
#
# @TODO better query handling
#
exports.getObjectsByType = (req, res, next) ->

  opts = exports._parseOptions req

  req.db.con.getDocuments req.db.col, opts, (err, documents) ->
    return next err if err
    return res.jsonp
      documents: documents
      count: documents.length

#
# Get object
#
# Get object for given ObjectId
# 
# @require req.db.con - database instance
# @require req.db.col - collection pointer
# @require req.db.id - DocumentID
#
# @TODO private field sharing
#
exports.getObjectById = (req, res, next) ->
  db  = req.db.con
  col = req.db.col
  id  = req.db.id

  db.getDocument col, id, (err, document) ->
    return next err if err
    return res.jsonp 404, {} if not document
    delete document.privat if document.eier isnt req.key.public
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


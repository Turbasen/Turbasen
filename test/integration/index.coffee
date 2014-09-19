exports.steder = module.parent.exports.steder
exports.turer = module.parent.exports.turer

describe '/', ->
  require './auth-int'
  require './notfound-int'

describe '/objekttyper', ->
  require './objekttyper-int'

describe '/system', ->
  require './system-int'

describe '/{type}', ->
  require './collection-int'

describe '/{type}/{id}', ->
  require './document-int'


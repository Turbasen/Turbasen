exports.steder = module.parent.exports.steder

describe 'Helpers', ->
  require './helper/'

describe 'Models', ->
  require './model/'

describe 'API', ->
  describe 'collection', ->
    require './collection-spec.coffee'

  describe 'document', ->
    require './document-spec.coffee'


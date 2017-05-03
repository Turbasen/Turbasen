request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

describe 'HEAD', ->
  url = '/turer?api_key=dnt'

  it 'should return 204 status code with no body', ->
    req.head url
      .expect 204
      .expect {}

  it 'should return correct headers', ->
    req.head(url)
      .expect 204
      .expect {}
      .expect 'count-return', '20'
      .expect 'count-total', '27'

describe 'GET', ->
  tilbyderMatching = (owner, res) ->
    owner = [owner] if not (owner instanceof Array)

    for doc in res.body.documents
      assert doc.tilbyder in owner

    return

  statusMatching = (status, res) ->
    status = [status] if not (status instanceof Array)

    for doc in res.body.documents
      assert doc.status in status

    return

  it 'should return 200 status code with documents', ->
    req.get '/steder?api_key=dnt'
      .expect 200
      .expect (res) ->
        assert res.body.documents instanceof Array
        assert.equal res.body.count, 20

  describe '?limit', ->
    it 'should limit number of documents returned', ->
      req.get '/steder?limit=10&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 10

    it 'should prevent limit higher then 100', ->
      req.get '/steder?limit=200&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 100

  describe '?skip', ->
    it 'should skip the 9 first documents', (done) ->
      req.get('/steder?api_key=dnt').end (err, res1) ->
        assert.ifError err
        skip = res1.body.documents.length - 1

        req.get("/steder?skip=#{skip}&api_key=dnt").end (err, res2) ->
          assert.ifError err
          assert.deepEqual res1.body.documents[skip], res2.body.documents[0]
          done()

      return

    it 'should skip majority of total number of documents', ->
      req.get '/steder?skip=110&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 10
          assert.equal res.body.total, 120
          assert.equal res.body.documents.length, 10

    it 'should skip past total number of documents', ->
      req.get '/steder?skip=130&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 0
          assert.equal res.body.total, 120
          assert.equal res.body.documents.length, 0

  describe '?sort', ->
    it 'should default to ascending last modified sort', ->
      req.get '/steder?api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.endret >= res.body.documents[i - 1].endret
          return

    it 'should sort ascending on _id', ->
      req.get '/steder?sort=_id&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc._id >= res.body.documents[i - 1]._id
          return

    it 'should sort decreasing on _id', ->
      req.get '/steder?sort=-_id&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc._id <= res.body.documents[i - 1]._id
          return

    it 'should sort ascending on endret', ->
      req.get '/steder?sort=endret&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.endret >= res.body.documents[i - 1].endret
          return

    it 'should sort decreasing on endret', ->
      req.get '/steder?sort=-endret&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.endret <= res.body.documents[i - 1].endret
          return

    it 'should sort ascending on navn', ->
      req.get '/steder?sort=navn&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.navn >= res.body.documents[i - 1].navn
          return

    it 'should sort decreasing on navn', ->
      req.get '/steder?sort=-navn&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.navn <= res.body.documents[i - 1].navn
          return

  describe '?fields', ->
    fieldsMatching = (fields, res) ->
      for doc in res.body.documents
        assert key in fields for key in Object.keys(doc)
      return

    it 'should return default fields', ->
      req.get '/steder?api_key=dnt'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags'
        ]

    it 'should always return tilbyder and lisens', ->
      req.get '/steder?fields=navn&api_key=dnt'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags'
        ]

    it 'should return chosen fields', ->
      req.get '/steder?fields=navn,geojson&api_key=dnt'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags',
          'geojson'
        ]

    it 'should return private fields', ->
      req.get '/steder?fields=navn,privat.secret,privat&api_key=dnt'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags',
          'privat'
        ]
        .expect tilbyderMatching.bind undefined, 'DNT'

    it 'should only return documents I own with private fileds', ->
      req.get '/steder?fields=navn,privat.secret,privat&api_key=nrk'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags',
          'privat'
        ]
        .expect tilbyderMatching.bind undefined, 'NRK'

  describe 'Queries', ->
    describe 'ACL', ->
      it 'returns my own or public documents', ->
        req.get '/steder?api_key=nrk'
          .expect 200
          .expect tilbyderMatching.bind undefined, ['NRK', 'DNT']
          .expect statusMatching.bind undefined, [
            'Offentlig', 'Privat', 'Kladd'
          ]

      it 'returns my documents', ->
        req.get '/steder?api_key=nrk&tilbyder=NRK'
          .expect 200
          .expect tilbyderMatching.bind undefined, 'NRK'

      it 'returns other\'s documents', ->
        req.get '/steder?api_key=dnt&tilbyder=NRK'
          .expect 200
          .expect tilbyderMatching.bind undefined, 'NRK'
          .expect statusMatching.bind undefined, 'Offentlig'

      it 'returns public documents', ->
        req.get '/steder?api_key=dnt&status=Offentlig'
          .expect 200
          .expect statusMatching.bind undefined, 'Offentlig'

      it 'returns public or deleted documents', ->
        req.get '/steder?api_key=dnt&status[]=Offentlig&&status[]=Slettet'
          .expect 200
          .expect statusMatching.bind undefined, ['Offentlig', 'Slettet']

    describe 'Basic Operators', ->
      it 'field should exist', ->
        req.get '/turer?bilder=&fields=bilder&api_key=dnt'
          .expect 200
          .expect (res) ->
            for doc in res.body.documents
              assert.notEqual typeof doc.bilder, 'undefined'
            return

      it 'field should not exist', ->
        req.get '/steder?bilder=!&fields=bilder&api_key=dnt'
          .expect 200
          .expect (res) ->
            for doc in res.body.documents
              assert.equal typeof res.bilder, 'undefined'
            return

      it 'field should equal string', ->
        req.get '/turer?tags.0=Skitur&api_key=dnt'
          .expect 200
          .expect 'count-total', '2'
          .expect (res) ->
            assert.equal sted.tags[0], 'Skitur' for sted in res.body.documents
            return

      it 'field should equal number', ->
        req.get '/steder?privat.opprettet_av.id=3456&api_key=dnt'
          .expect 200
          .expect 'count-total', '17'

      it 'field should not equal string', ->
        req.get '/turer?tags.0=!Fottur&api_key=dnt'
          .expect 200
          .expect 'count-total', '2'
          .expect (res) ->
            assert.notEqual tur.tags[0], 'Fottur' for tur in res.body.documents
            return

      it 'field should not equal number', ->
        req.get '/steder?privat.opprettet_av.id=!3456&api_key=dnt'
          .expect 200
          .expect 'count-total', '103'

      it 'field should start with string', ->
        req.get '/steder?navn=^b&api_key=dnt'
          .expect 200
          .expect 'count-total', '10'

      it 'field should end with string', ->
        req.get '/steder?navn=$0&api_key=dnt'
          .expect 200
          .expect 'count-total', '9'

      it 'field should contain string', ->
        req.get '/steder?navn=~033&api_key=dnt'
          .expect 200
          .expect 'count-total', '3'

      it 'field should be greater than', ->
        req.get '/steder?privat.opprettet_av.id=>1234&api_key=dnt'
          .expect 200
          .expect 'count-total', '37'

      it 'field should be less than', ->
        req.get '/steder?privat.opprettet_av.id=<3456&api_key=dnt'
          .expect 200
          .expect 'count-total', '19'

    describe 'Custom Operators', ->
      describe '?after', ->
        documentCount = (count, res) ->
          assert.equal res.body.count, count

        documentAfter = (after, res) ->
          for doc in res.body.documents
            assert doc.endret >= after, "#{doc.endret} >= #{after}"
          return

        it 'should return documents changed after UTZ datestamp', ->
          date = '2014-06-01T17:42:39.766Z'
          req.get "/turer?after=#{date}&api_key=dnt"
            .expect 200
            .expect documentCount.bind(undefined, 10)
            .expect documentAfter.bind(undefined, date)

        it 'should return documents changed after ms from 1.1.1970', ->
          date = new Date '2014-06-01T17:42:39.766Z'
          req.get "/turer?after=#{date.getTime()}&api_key=dnt"
            .expect 200
            .expect documentCount.bind(undefined, 10)
            .expect documentAfter.bind(undefined, date.toISOString())

      describe '?bbox', ->
        it 'should return documents within bbox', ->
          coords = [
            '5.3633880615234375', '60.777937176256515'
            '6.52862548828125', '61.044326483979894'
          ].join(',')

          req.get "/steder?bbox=#{coords}&api_key=dnt"
            .expect 200
            .expect 'count-total', '7'
            .expect (res) ->
              # @TODO assert geometry for doc in res.body.documents
              return

      describe '?near', ->
        it 'should return documents near coordinate', ->
          coords = '6.22051,60.96570'
          req.get "/steder?near=#{coords}&api_key=dnt"
            .expect 200
            .expect (res) ->
              assert.equal res.body.documents[0]._id, '52407fb375049e5615000460'

    describe 'Leggacy Fields', ->
      it '?tag should query on tags.0', ->
        req.get '/turer?tag=Fottur&api_key=dnt'
          .expect 200
          .expect 'count-total', '25'
          .expect (res) ->
            assert.equal sted.tags[0], 'Fottur' for sted in res.body.documents
            return

      it '?gruppe should query on grupper', ->
        gruppe = '52407f3c4ec4a1381500025d'
        req.get "/steder?gruppe=#{gruppe}&fields=grupper&api_key=dnt"
          .expect 200
          .expect 'count-total', '26'
          .expect (res) ->
            assert gruppe in doc.grupper for doc in res.body.documents
            return

describe 'POST', ->
  url = '/turer?api_key=dnt'

  it 'should return 400 status code for missing body', ->
    req.post url
      .expect 400, message: 'Body is missing'

  it 'should return 402 status code for invalid body type', ->
    req.post url
      .send ['foo', 'bar']
      .expect 422
      .expect message: 'Body should be a JSON Hash'

  it 'should return 402 status code for invalid data schema', ->
    req.post url
      .send navn: 123
      .expect 422
      .expect (res) ->
        assert.equal typeof res.body.document, 'object'
        assert.equal typeof res.body.errors, 'object'
        assert.deepEqual res.body.message, 'Validation Failed'

  it 'should return 201 status code for successfull post', ->
    req.post url
      .send navn: 'Test'
      .expect 201
      .expect 'etag', /^"[0-9a-f]{40}"$/
      .expect 'last-modified', /\w/
      .expect (res) ->
        assert.equal res.body.document.navn, 'Test'

  it 'should return warnings for missing data fileds', ->
    req.post url
      .send navn: 'Test'
      .expect 201
      .expect (res) ->
        assert.equal res.body.message, 'Validation Warnings'
        assert.deepEqual res.body.warnings, [
          { resource: 'Document', field: 'lisens', code: 'missing_field' }
          { resource: 'Document', field: 'navngiving', code: 'missing_field' }
          { resource: 'Document', field: 'status', code: 'missing_field' }
        ]

  it 'should succeed posting to områder collection', ->
    req.post '/omr%C3%A5der?api_key=dnt'
      .send navn: 'Test'
      .expect 201
      .expect (res) ->
        assert.equal res.body.document.navn, 'Test'

for method in ['put', 'patch', 'delete']
  describe method.toUpperCase(), ->
    it 'should return 405 Method Not Allowed status', ->
      req[method]('/steder?api_key=dnt')
        .expect 405
        .expect message: "HTTP Method #{method.toUpperCase()} Not Allowed"

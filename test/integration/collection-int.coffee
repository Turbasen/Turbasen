request = require 'supertest'
assert  = require 'assert'

req     = request require './../../coffee/server'

describe 'HEAD', ->
  url = '/turer?api_key=dnt'

  it 'should return 204 status code with no body', (done) ->
    req.head url
      .expect 204, {}
      .end done

  it 'should return correct headers', (done) ->
    req.head(url)
      .expect 204, {}
      .expect 'count-return', '20'
      .expect 'count-total', '27'
      .end done

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

  it 'should return 200 status code with documents', (done) ->
    req.get '/steder?api_key=dnt'
      .expect 200
      .expect (res) ->
        assert res.body.documents instanceof Array
        assert.equal res.body.count, 20
      .end done

  describe '?limit', ->
    it 'should limit number of documents returned', (done) ->
      req.get '/steder?limit=10&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 10
        .end done

    it 'should prevent limit higher then 50', (done) ->
      req.get '/steder?limit=100&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 50
        .end done

  describe '?skip', ->
    it 'should skip the 9 first documents', (done) ->
      req.get('/steder?api_key=dnt').end (err, res1) ->
        assert.ifError err
        skip = res1.body.documents.length - 1

        req.get("/steder?skip=#{skip}&api_key=dnt").end (err, res2) ->
          assert.ifError err
          assert.deepEqual res1.body.documents[skip], res2.body.documents[0]
          done()

    it 'should skip majority of total number of documents', (done) ->
      req.get '/steder?skip=110&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 10
          assert.equal res.body.total, 120
          assert.equal res.body.documents.length, 10
        .end done

    it 'should skip past total number of documents', (done) ->
      req.get '/steder?skip=130&api_key=dnt'
        .expect 200
        .expect (res) ->
          assert.equal res.body.count, 0
          assert.equal res.body.total, 120
          assert.equal res.body.documents.length, 0
        .end done

  describe '?sort', ->
    it 'should default to ascending last modified sort', (done) ->
      req.get '/steder?api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.endret >= res.body.documents[i-1].endret
          return
        .end done

    it 'should sort ascending on _id', (done) ->
      req.get '/steder?sort=_id&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc._id >= res.body.documents[i-1]._id
          return
        .end done

    it 'should sort decreasing on _id', (done) ->
      req.get '/steder?sort=-_id&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc._id <= res.body.documents[i-1]._id
          return
        .end done

    it 'should sort ascending on endret', (done) ->
      req.get '/steder?sort=endret&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.endret >= res.body.documents[i-1].endret
          return
        .end done

    it 'should sort decreasing on endret', (done) ->
      req.get '/steder?sort=-endret&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.endret <= res.body.documents[i-1].endret
          return
        .end done

    it 'should sort ascending on navn', (done) ->
      req.get '/steder?sort=navn&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.navn >= res.body.documents[i-1].navn
          return
        .end done

    it 'should sort decreasing on navn', (done) ->
      req.get '/steder?sort=-navn&api_key=dnt'
        .expect 200
        .expect (res) ->
          for doc, i in res.body.documents when i > 0
            assert doc.navn <= res.body.documents[i-1].navn
          return
        .end done

  describe '?fields', ->
    fieldsMatching = (fields, res) ->
      for doc in res.body.documents
        assert key in fields for key in Object.keys(doc)
      return

    it 'should return default fields', (done) ->
      req.get '/steder?api_key=dnt'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags'
        ]
        .end done

    it 'should always return tilbyder and lisens', (done) ->
      req.get '/steder?fields=navn&api_key=dnt'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags'
        ]
        .end done

    it 'should return chosen fields', (done) ->
      req.get '/steder?fields=navn,geojson&api_key=dnt'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags',
          'geojson'
        ]
        .end done

    it 'should return private fields', (done) ->
      req.get '/steder?fields=navn,privat.secret,privat&api_key=dnt'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags',
          'privat'
        ]
        .expect tilbyderMatching.bind undefined, 'DNT'
        .end done

    it 'should only return documents I own with private fileds', (done) ->
      req.get '/steder?fields=navn,privat.secret,privat&api_key=nrk'
        .expect 200
        .expect fieldsMatching.bind undefined, [
          '_id', 'tilbyder', 'endret', 'status', 'lisens', 'navn', 'tags',
          'privat'
        ]
        .expect tilbyderMatching.bind undefined, 'NRK'
        .end done

  describe 'Queries', ->
    describe 'ACL', ->
      it 'returns my own or public documents', (done) ->
        req.get '/steder?api_key=nrk'
          .expect 200
          .expect tilbyderMatching.bind undefined, ['NRK', 'DNT']
          .expect statusMatching.bind undefined, [
            'Offentlig', 'Privat', 'Kladd'
          ]
          .end done

      it 'returns my documents', (done) ->
        req.get '/steder?api_key=nrk&tilbyder=NRK'
          .expect 200
          .expect tilbyderMatching.bind undefined, 'NRK'
          .end done

      it 'returns other\'s documents', (done) ->
        req.get '/steder?api_key=dnt&tilbyder=NRK'
          .expect 200
          .expect tilbyderMatching.bind undefined, 'NRK'
          .expect statusMatching.bind undefined, 'Offentlig'
          .end done

      it 'returns public documents', (done) ->
        req.get '/steder?api_key=dnt&status=Offentlig'
          .expect 200
          .expect statusMatching.bind undefined, 'Offentlig'
          .end done

      it 'returns public or deleted documents', (done) ->
        req.get '/steder?api_key=dnt&status[]=Offentlig&&status[]=Slettet'
          .expect 200
          .expect statusMatching.bind undefined, ['Offentlig', 'Slettet']
          .end done

    describe 'Basic Operators', ->
      it 'field should exist', (done) ->
        req.get '/turer?bilder=&fields=bilder&api_key=dnt'
          .expect 200
          .expect (res) ->
            for doc in res.body.documents
              assert.notEqual typeof doc.bilder, 'undefined'
            return
          .end done

      it 'field should not exist', (done) ->
        req.get '/steder?bilder=!&fields=bilder&api_key=dnt'
          .expect 200
          .expect (res) ->
            for doc in res.body.documents
              assert.equal typeof res.bilder, 'undefined'
            return
          .end done

      it 'field should equal string', (done) ->
        req.get '/turer?tags.0=Skitur&api_key=dnt'
          .expect 200
          .expect 'count-total', 2
          .expect (res) ->
            assert.equal sted.tags[0], 'Skitur' for sted in res.body.documents
            return
          .end done

      it 'field should equal number', (done) ->
        req.get '/steder?privat.opprettet_av.id=3456&api_key=dnt'
          .expect 200
          .expect 'count-total', 17
          .end done

      it 'field should not equal string', (done) ->
        req.get '/turer?tags.0=!Fottur&api_key=dnt'
          .expect 200
          .expect 'count-total', 2
          .expect (res) ->
            assert.notEqual tur.tags[0], 'Fottur' for tur in res.body.documents
            return
          .end done

      it 'field should not equal number', (done) ->
        req.get '/steder?privat.opprettet_av.id=!3456&api_key=dnt'
          .expect 200
          .expect 'count-total', 103
          .end done

      it 'field should start with string', (done) ->
        req.get '/steder?navn=^b&api_key=dnt'
          .expect 200
          .expect 'count-total', 10
          .end done

      it 'field should end with string', (done) ->
        req.get '/steder?navn=$0&api_key=dnt'
          .expect 200
          .expect 'count-total', 9
          .end done

      it 'field should contain string', (done) ->
        req.get '/steder?navn=~033&api_key=dnt'
          .expect 200
          .expect 'count-total', 3
          .end done

      it 'field should be greater than', (done) ->
        req.get '/steder?privat.opprettet_av.id=>1234&api_key=dnt'
          .expect 200
          .expect 'count-total', 37
          .end done

      it 'field should be less than', (done) ->
        req.get '/steder?privat.opprettet_av.id=<3456&api_key=dnt'
          .expect 200
          .expect 'count-total', 19
          .end done

    describe 'Custom Operators', ->
      describe '?after', ->
        documentCount = (count, res) ->
          assert.equal res.body.count, count

        documentAfter = (after, res) ->
          for doc in res.body.documents
            assert doc.endret >= after, "#{doc.endret} >= #{after}"
          return

        it 'should return documents changed after UTZ datestamp', (done) ->
          date = '2014-06-01T17:42:39.766Z'
          req.get "/turer?after=#{date}&api_key=dnt"
            .expect 200
            .expect documentCount.bind(undefined, 10)
            .expect documentAfter.bind(undefined, date)
            .end done

        it 'should return documents changed after ms from 1.1.1970', (done) ->
          date = new Date '2014-06-01T17:42:39.766Z'
          req.get "/turer?after=#{date.getTime()}&api_key=dnt"
            .expect 200
            .expect documentCount.bind(undefined, 10)
            .expect documentAfter.bind(undefined, date.toISOString())
            .end done

      describe '?bbox', ->
        it 'should return documents within bbox', (done) ->
          coords = [
            '5.3633880615234375', '60.777937176256515'
            '6.52862548828125', '61.044326483979894'
          ].join(',')

          req.get "/steder?bbox=#{coords}&api_key=dnt"
            .expect 200
            .expect 'count-total', 7
            .expect (res) ->
              # @TODO assert geometry for doc in res.body.documents
              return
            .end done

      describe '?near', ->
        it 'should return documents near coordinate', (done) ->
          coords = '6.22051,60.96570'
          req.get "/steder?near=#{coords}&api_key=dnt"
            .expect 200
            .expect (res) ->
              assert.equal res.body.documents[0]._id, '52407fb375049e5615000460'
          .end done

    describe 'Leggacy Fields', ->
      it '?tag should query on tags.0', (done) ->
        req.get '/turer?tag=Fottur&api_key=dnt'
          .expect 200
          .expect 'count-total', 25
          .expect (res) ->
            assert.equal sted.tags[0], 'Fottur' for sted in res.body.documents
            return
          .end done

      it '?gruppe should query on grupper', (done) ->
        gruppe = '52407f3c4ec4a1381500025d'
        req.get "/steder?gruppe=#{gruppe}&fields=grupper&api_key=dnt"
          .expect 200
          .expect 'count-total', 26
          .expect (res) ->
            assert gruppe in doc.grupper for doc in res.body.documents
            return
          .end done

describe 'POST', ->
  url = '/turer?api_key=dnt'

  it 'should return 400 status code for missing body', (done) ->
    req.post url
      .expect 400, message: 'Body is missing'
      .end done

  it 'should return 402 status code for invalid body type', (done) ->
    req.post url
      .send ['foo', 'bar']
      .expect 422, message: 'Body should be a JSON Hash'
      .end done

  it 'should return 402 status code for invalid data schema', (done) ->
    req.post url
      .send navn: 123
      .expect 422
      .expect (res) ->
        assert.equal typeof res.body.document, 'object'
        assert.equal typeof res.body.errors, 'object'
        assert.deepEqual res.body.message, 'Validation Failed'
      .end done

  it 'should return 201 status code for successfull post', (done) ->
    req.post url
      .send navn: 'Test'
      .expect 201
      .expect 'etag', /^"[0-9a-f]{40}"$/
      .expect 'last-modified', /\w/
      .expect (res) ->
        assert.equal res.body.document.navn, 'Test'
      .end done

  it 'should return warnings for missing data fileds', (done) ->
    req.post url
      .send navn: 'Test'
      .expect 201
      .expect (res) ->
        assert.equal res.body.message, 'Validation Warnings'
        assert.deepEqual res.body.warnings, [
          {resource: 'Document', field: 'lisens', code: 'missing_field'}
          {resource: 'Document', field: 'navngiving', code: 'missing_field'}
          {resource: 'Document', field: 'status', code: 'missing_field'}
        ]
      .end done

  it 'should succeed posting to områder collection', (done) ->
    req.post '/omr%C3%A5der?api_key=dnt'
      .send navn: 'Test'
      .expect 201
      .expect (res) ->
        assert.equal res.body.document.navn, 'Test'
      .end done

for method in ['put', 'patch', 'delete']
  describe method.toUpperCase(), ->
    it 'should return 405 Method Not Allowed status', (done) ->
      req[method]('/steder?api_key=dnt')
        .expect 405, message: "HTTP Method #{method.toUpperCase()} Not Allowed"
        .end done


MongoClient = require('mongodb').MongoClient
program = require 'commander'

program
  .version('1.0.0')
  .option('-u, --uri [mongouri]', 'MongoDB URI to connect to')
  .option('-t, --type [datatype]', 'Data type to delete for')
  .parse(process.argv)

types =
  arrangementer: {}
  grupper: {}
  steder:
    query: 'tags.0': {$ne: 'Hytte'}
  hytter:
    col: 'steder'
    query: 'tags.0': 'Hytte'
  bilder: {}
  turer: {}
  områder: {}

return program.help() if not program.uri or not program.type or not types[program.type]

type = types[program.type]
type.col = program.type if not type.col
type.query.tilbyder = 'DNT' if type.query
type.query = tilbyder: 'DNT' if not type.query

log = (msg) ->
  d = new Date()
  dd = d.getUTCDate()
  dm = d.getUTCMonth()
  dy = d.getUTCFullYear()
  th = d.getUTCHours()
  tm = d.getUTCMinutes()
  ts = d.getUTCSeconds()
  dd = '0' + dd if dd < 10
  dm = '0' + dm if dm < 10
  th = '0' + th if th < 10
  tm = '0' + tm if tm < 10
  ts = '0' + ts if ts < 10

  console.log "#{dy}-#{dm}-#{dd} #{th}:#{tm}:#{ts} #{msg}"

log 'Connecting to database...'
MongoClient.connect "#{program.uri}", (err, db) ->
  throw err if err

  log 'Database is connected!'
  log "Deleting documents from collection '#{type.col}'..."

  db.collection(type.col).remove type.query, (err, count) ->
    throw err if err
    log "#{count} documents deleted!"
    log 'Closing database connection...'
    db.close ->
      log 'Database connection closed!'
      log 'Shutting down!'


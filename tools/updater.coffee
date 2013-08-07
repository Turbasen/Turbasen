database = require './../coffee/database.coffee'

collection = 'ntb_07'

database collection, (err, db) ->
  return console.log err if err

  console.log 'Database connection is open'
  console.log "Collection is #{collection}"

  db.collection 'aktiviteter', (err, collection) ->
    return console.log(err) if err
  
    collection.count (err, count) ->
      return console.log(err) if err
  
      console.log(count)

      db.close()

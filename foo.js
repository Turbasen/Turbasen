var mongodb = require('mongodb');

var replSet = new mongodb.ReplSetServers([
  new mongodb.Server('localhost', 27017),
  new mongodb.Server('localhost', 27018),
  new mongodb.Server('localhost', 27019)
]);

var db = new mongodb.Db('test', replSet, {w:0});

db.on('error', function(err) {
  console.log('fuck', err);
});

process.on("uncaughtException", function(err) {
  console.log(err);
});

db.open(function(err, db) {
  console.log('open');
  thisMethodDoesNotExists('foo', 'bar', 123);
});

